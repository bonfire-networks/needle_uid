defmodule Needle.UID do
  @moduledoc "./README.md" |> File.stream!() |> Enum.drop(1) |> Enum.join()
  use Ecto.ParameterizedType
  import Untangle, except: [dump: 3]

  @pride_enabled Application.compile_env(:needle_uid, :pride_enabled, false)
  @ulid_enabled Application.compile_env(:needle_uid, :ulid_enabled, true)

  @doc "translates alphanumerics into a sentinel ID value"
  def synthesise!(x) when is_binary(x) do
    # TODO with UUID
    Needle.ULID.synthesise!(x)
  end

  @doc """
  The underlying schema type.
  """
  @impl true
  def type(_params), do: :uuid

  @impl true
  def init(opts) do
    if @pride_enabled do
      if Keyword.get(opts, :prefix) do
        IO.warn("use prefixed UUIDv7 for #{inspect(opts)}")
        Pride.init(opts)
      else
        IO.warn("fallback to ULID for #{inspect(opts)}")
        Pride.init(opts ++ [allow_unprefixed: true])
      end
    else
      opts
    end
  end

  @impl true
  def equal?(a, b, params \\ nil)

  if @pride_enabled do
    def equal?(a, b, %{prefix: _} = params), do: Pride.equal?(a, b, params)
  end

  if @ulid_enabled do
    def equal?(a, b, _), do: Needle.ULID.equal?(a, b)
  end

  @impl true
  def embed_as(format, params \\ nil)

  if @pride_enabled do
    def embed_as(format, %{prefix: _} = params), do: Pride.embed_as(format, params)
  end

  if @ulid_enabled do
    def embed_as(format, _), do: Needle.ULID.embed_as(format)
  end

  @impl true
  def autogenerate(params), do: generate(params)
  def generate(params_or_timestamp \\ nil)

  if @pride_enabled do
    def generate(%{prefix: _} = params), do: Pride.autogenerate(params)
  end

  if @ulid_enabled do
    def generate(timestamp) when is_integer(timestamp), do: Needle.ULID.generate(timestamp)
  end

  if @pride_enabled do
    def generate(schema) when is_atom(schema) and not is_nil(schema) do
      debug(schema, "gen schema")

      if function_exported?(schema, :__schema__, 1) do
        # hopefully ok to just take the first?
        case schema.__schema__(:primary_key) |> List.first() |> debug("gen primary_key first") do
          nil ->
            if @ulid_enabled do
              Needle.ULID.generate()
            end

          field ->
            generate(schema, field)
        end
      else
        if @ulid_enabled do
          Needle.ULID.generate()
        end
      end
    end
  end

  if @ulid_enabled do
    def generate(_), do: Needle.ULID.generate()
  end

  if @pride_enabled do
    def generate(schema, field) when is_atom(schema) do
      case Pride.params(schema, field) |> debug("gen prefix") do
        %{prefix: _} = params ->
          Pride.autogenerate(params)

        _ ->
          if @ulid_enabled do
            Needle.ULID.generate()
          end
      end
    end
  end

  @doc "Returns the timestamp of an encoded or unencoded UID"
  if @ulid_enabled do
    def timestamp(<<_::bytes-size(26)>> = encoded) do
      Needle.ULID.timestamp(encoded)
    end
  end

  def timestamp(encoded) do
    # TODO for UUID
  end

  @doc """
  Casts an encoded string to ID. Transforms outside data into runtime data.

  Used to (potentially) convert your data into an internal normalized representation which will be part of your changesets. It also used for verifying that something is actually valid input data for your type.
  """
  @impl true
  def cast(term, params \\ nil)
  def cast(nil, _params), do: {:ok, nil}

  if @pride_enabled do
    def cast(term, %{prefix: _} = params) do
      with {:error, _} <- Pride.cast(term, params) do
        # for old ULIDs in a prefixed table
        if @ulid_enabled and Needle.ULID.valid?(term) do
          {:ok, term}
        else
          {:error, message: "Not recognised as valid Prefixed UUIDv7 or ULID"}
        end
      end
    end
  end

  def cast(<<_::bytes-size(16)>> = value, _), do: {:ok, value}

  def cast(<<_::bytes-size(26)>> = value, params) do
    if @ulid_enabled and Needle.ULID.valid?(value) do
      {:ok, value}
    else
      if @pride_enabled do
        Pride.cast(value, params)
      else
        {:error, message: "Invalid ULID"}
      end
    end
  end

  if @pride_enabled do
    def cast(term, %{} = params), do: Pride.cast(term, params)
  end

  def cast(_, _), do: {:error, message: "Not recognised as valid Prefixed UUIDv7 or ULID"}

  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  @impl true
  def cast!(value, params \\ nil) do
    case cast(value, params) do
      {:ok, uid} ->
        uid

      {:error, term} ->
        raise Ecto.CastError, type: __MODULE__, value: value, message: term[:message]

      :error ->
        raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  @doc """
  Converts an encoded ID into a binary. Used to get your data ready to be written to the database. Transforms anything (outside data or runtime data) into database column data
  """
  @impl true
  def dump(value, dumper \\ nil, params \\ nil)
  def dump(nil, _, _), do: {:ok, nil}

  if @pride_enabled do
    def dump(value, dumper, %{prefix: _} = params), do: Pride.dump(value, dumper, params)
  end

  if @ulid_enabled do
    def dump(<<_::bytes-size(26)>> = encoded, _, _), do: Needle.ULID.decode(encoded)
  end

  if @pride_enabled do
    def dump(value, dumper, %{} = params), do: Pride.dump(value, dumper, params)
  end

  def dump(_, _, _), do: :error

  @impl true
  def dump!(encoded, dumper \\ nil, params \\ nil) do
    case dump(encoded, dumper, params) do
      {:ok, uid} -> uid
      _ -> raise Ecto.CastError, type: __MODULE__, value: encoded
    end
  end

  @doc """
  Converts a binary ID into an encoded string. Transforms database column data into runtime data.
  """
  @impl true
  def load(value, loader \\ nil, params \\ nil)
  def load(nil, _, _), do: {:ok, nil}

  if @pride_enabled do
    def load(value, loader, %{prefix: _} = params), do: Pride.load(value, loader, params)
  end

  if @pride_enabled do
    def load(value, loader, %{} = params) do
      with :error <- Pride.load(value, loader, params) do
        if @ulid_enabled do
          Needle.ULID.encode(value)
        else
          :error
        end
      end
    end
  end

  if @ulid_enabled do
    def load(bytes, _, _) when is_binary(bytes) and byte_size(bytes) == 16,
      do: Needle.ULID.encode(bytes)
  end

  def load(_, _, _), do: :error

  @doc """
  Takes a string and returns true if it is a valid ULID (Universally Unique Lexicographically Sortable Identifier).

  ## Examples
      iex> is_ulid?("01J3MQ2Q4RVB1WTE3KT1D8ZNX1")
      true

      iex> is_ulid?("invalid_ulid")
      false
  """
  def is_ulid?(str) when is_binary(str) and byte_size(str) == 26 do
    Needle.ULID.valid?(str)
  end

  def is_ulid?(_), do: false

  @doc """
  Takes a string and returns true if it is a valid Object ID or Prefixed UUID (Universally Unique Identifier).

  ## Examples
      iex> is_uuid?("550e8400-e29b-41d4-a716-446655440000")
      true

      iex> is_uuid?("invalid_uuid")
      false
  """
  def is_uuid?(str, params \\ nil)

  def is_uuid?(str, params) when is_binary(str) and byte_size(str) == 36 do
    with {:ok, _} <- Ecto.UUID.cast(str) do
      true
    else
      _ ->
        if @pride_enabled do
          is_pride?(str, params)
        else
          false
        end
    end
  end

  def is_uuid?(str, params), do: is_pride?(str, params)

  def is_pride?(str, params \\ nil)

  def is_pride?(str, params) do
    case Pride.valid_or_uuid(str, params) do
      true -> true
      false -> false
      uuid -> uuid
    end
  end

  def is_pride?(_, _), do: false
end
