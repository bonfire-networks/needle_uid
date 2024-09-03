if Code.ensure_loaded?(Uniq.UUID) do
  defmodule Needle.UID.PrideTest do
    use ExUnit.Case, async: true
    import Untangle
    alias Needle.UID
    alias Uniq.UUID

    # function_exported?(Needle.UID, :type, 1)
    # |> IO.inspect(label: "have func")

    # Ecto.ParameterizedType.init(Needle.UID, [field: :id, schema: FirstTestSchema, prefix: "test", autogenerate: true])
    # |> IO.inspect(label: "param")

    defmodule TestSchema do
      use Ecto.Schema

      @primary_key {:id, Needle.UID, prefix: "test", autogenerate: true}
      @foreign_key_type Needle.UID

      schema "test" do
        belongs_to(:test, TestSchema)
      end
    end

    @params UID.init(
              schema: TestSchema,
              field: :id,
              primary_key: true,
              autogenerate: true,
              prefix: "test"
            )
    @belongs_to_params UID.init(schema: TestSchema, field: :test, foreign_key: :test_id)
    @loader nil
    @dumper nil

    @test_prefixed_uuid "test_3TUIKuXX5mNO2jSA41bsDx"
    @test_uuid UUID.to_string("7232b37d-fc13-44c0-8e1b-9a5a07e24921", :raw)
    @test_prefixed_uuid_with_leading_zero "test_02tREKF6r6OCO2sdSjpyTm"
    @test_uuid_with_leading_zero UUID.to_string("0188a516-bc8c-7c5a-9b68-12651f558b9e", :raw)
    @test_prefixed_uuid_null "test_0000000000000000000000"
    @test_uuid_null UUID.to_string("00000000-0000-0000-0000-000000000000", :raw)
    @test_prefixed_uuid_invalid_characters "test_" <> String.duplicate(".", 32)
    @test_uuid_invalid_characters String.duplicate(".", 22)
    @test_prefixed_uuid_invalid_format "test_" <> String.duplicate("x", 31)
    @test_uuid_invalid_format String.duplicate("x", 21)

    test "cast/2" do
      assert UID.cast(@test_prefixed_uuid, @params) == {:ok, @test_prefixed_uuid}

      assert UID.cast(@test_prefixed_uuid_with_leading_zero, @params) ==
               {:ok, @test_prefixed_uuid_with_leading_zero}

      assert UID.cast(@test_prefixed_uuid_null, @params) == {:ok, @test_prefixed_uuid_null}
      assert UID.cast(nil, @params) == {:ok, nil}
      assert {:error, _} = UID.cast("otherprefix" <> @test_prefixed_uuid, @params)
      assert {:error, _} = UID.cast(@test_prefixed_uuid_invalid_characters, @params)
      assert {:error, _} = UID.cast(@test_prefixed_uuid_invalid_format, @params)
      assert UID.cast(@test_prefixed_uuid, @belongs_to_params) == {:ok, @test_prefixed_uuid}

      assert {:error, _} = UID.cast("http://localhost/Erdman_Runolfsdottir", @params)
      refute UID.is_uuid?("http://localhost/Erdman_Runolfsdottir", @params)
      refute UID.is_uuid?("http://localhost/Erdman_Runolfsdottir")
    end

    test "load/3" do
      assert UID.load(@test_uuid, @loader, @params) == {:ok, @test_prefixed_uuid}

      assert UID.load(@test_uuid_with_leading_zero, @loader, @params) ==
               {:ok, @test_prefixed_uuid_with_leading_zero}

      assert UID.load(@test_uuid_null, @loader, @params) == {:ok, @test_prefixed_uuid_null}
      assert UID.load(@test_uuid_invalid_characters, @loader, @params) == :error
      assert UID.load(@test_uuid_invalid_format, @loader, @params) == :error
      assert UID.load(@test_prefixed_uuid, @loader, @params) == :error
      assert UID.load(nil, @loader, @params) == {:ok, nil}
      assert UID.load(@test_uuid, @loader, @belongs_to_params) == {:ok, @test_prefixed_uuid}
    end

    test "dump/3" do
      assert UID.dump(@test_prefixed_uuid, @dumper, @params) == {:ok, @test_uuid}

      assert UID.dump(@test_prefixed_uuid_with_leading_zero, @dumper, @params) ==
               {:ok, @test_uuid_with_leading_zero}

      assert UID.dump(@test_prefixed_uuid_null, @dumper, @params) == {:ok, @test_uuid_null}
      assert UID.dump(@test_uuid, @dumper, @params) == :error
      assert UID.dump(nil, @dumper, @params) == {:ok, nil}
      assert UID.dump(@test_prefixed_uuid, @dumper, @belongs_to_params) == {:ok, @test_uuid}
    end

    test "autogenerate/1" do
      assert prefixed_uuid = UID.autogenerate(@params)
      assert {:ok, uuid} = UID.dump(prefixed_uuid, nil, @params)
      assert {:ok, %UUID{format: :raw, version: 7}} = UUID.parse(uuid)
    end

    test "generate/1 looks up the schema to determine what to generate" do
      ulid =
        Needle.UID.generate(TestSchema)
        |> debug()

      assert Needle.UID.is_uuid?(ulid)
      refute Needle.UID.is_ulid?(ulid)
    end
  end
end
