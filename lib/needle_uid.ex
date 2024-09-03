defmodule Needle.UID do
  @moduledoc "./README.md" |> File.stream!() |> Enum.drop(1) |> Enum.join()
  use Ecto.ParameterizedType
  import Untangle, except: [dump: 3]

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
    if Keyword.get(opts, :prefix) do
      IO.warn("use prefixed UUIDv7 for #{inspect(opts)}")
      Pride.init(opts)
    else
      IO.warn("fallback to ULID for #{inspect(opts)}")
      Pride.init(opts ++ [allow_unprefixed: true])
    end
  end

  @impl true
  def equal?(a, b, params \\ nil)
  def equal?(a, b, %{prefix: _} = params), do: Pride.equal?(a, b, params)
  def equal?(a, b, _), do: Needle.ULID.equal?(a, b)

  @impl true
  def embed_as(format, params \\ nil)
  def embed_as(format, %{prefix: _} = params), do: Pride.embed_as(format, params)
  def embed_as(format, _), do: Needle.ULID.embed_as(format)

  @impl true
  def autogenerate(params \\ nil), do: generate(params)
  def generate(params_or_timestamp \\ nil)
  def generate(%{prefix: _} = params), do: Pride.autogenerate(params)
  def generate(timestamp) when is_integer(timestamp), do: Needle.ULID.generate(timestamp)
  def generate(nil), do: Needle.ULID.generate()

  def generate(schema) when is_atom(schema) do
    debug(schema, "gen schema")

    if function_exported?(schema, :__schema__, 1) do
      # hopefully ok to just take the first?
      case schema.__schema__(:primary_key) |> List.first() |> debug("gen primary_key first") do
        nil -> Needle.ULID.generate()
        field -> generate(schema, field)
      end
    else
      Needle.ULID.generate()
    end
  end

  def generate(_), do: Needle.ULID.generate()

  def generate(schema, field) when is_atom(schema) do
    case Pride.params(schema, field) |> debug("gen prefix") do
      %{prefix: _} = params ->
        Pride.autogenerate(params)

      _ ->
        Needle.ULID.generate()
    end
  end

  @doc "Returns the timestamp of an encoded or unencoded UID"
  def timestamp(<<_::bytes-size(26)>> = encoded) do
    Needle.ULID.timestamp(encoded)
  end

  def timestamp(encoded) do
    # TODO for UUID
  end

  @doc """
  Casts an encoded string to ID 
  """
  @impl true
  def cast(term, params \\ nil)
  def cast(nil, _params), do: {:ok, nil}
  def cast(term, %{prefix: _} = params), do: Pride.cast(term, params)
  def cast(<<_::bytes-size(16)>> = value, _), do: {:ok, value}

  def cast(<<_::bytes-size(26)>> = value, _) do
    if Needle.ULID.valid?(value) do
      {:ok, value}
    else
      {:error, message: "Not recognised as valid ULID"}
    end
  end

  def cast(term, %{} = params), do: Pride.cast(term, params)
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
  Converts an encoded ID into a binary.
  """
  @impl true
  def dump(value, dumper \\ nil, params \\ nil)
  def dump(nil, _, _), do: {:ok, nil}
  def dump(value, dumper, %{prefix: _} = params), do: Pride.dump(value, dumper, params)
  def dump(<<_::bytes-size(26)>> = encoded, _, _), do: Needle.ULID.decode(encoded)
  def dump(value, dumper, %{} = params), do: Pride.dump(value, dumper, params)
  def dump(_, _, _), do: :error

  @impl true
  def dump!(encoded, dumper \\ nil, params \\ nil) do
    case dump(encoded, dumper, params) do
      {:ok, uid} -> uid
      _ -> raise Ecto.CastError, type: __MODULE__, value: encoded
    end
  end

  @doc """
  Converts a binary ID into an encoded string.
  """
  @impl true
  def load(value, loader \\ nil, params \\ nil)
  def load(nil, _, _), do: {:ok, nil}
  def load(value, loader, %{prefix: _} = params), do: Pride.load(value, loader, params)

  def load(value, loader, %{} = params) do
    with :error <- Pride.load(value, loader, params) do
      Needle.ULID.encode(value)
    end
  end

  def load(bytes, _, _) when is_binary(bytes) and byte_size(bytes) == 16,
    do: Needle.ULID.encode(bytes)

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
  def is_uuid?(str) when is_binary(str) and byte_size(str) == 36 do
    with {:ok, _} <- Ecto.UUID.cast(str) do
      true
    else
      _ -> is_pride?(str)
    end
  end

  def is_uuid?(str), do: is_pride?(str)

  def is_pride?(str) when is_binary(str) and byte_size(str) > 23 do
    Pride.valid?(str)
  end

  def is_pride?(_), do: false
end
