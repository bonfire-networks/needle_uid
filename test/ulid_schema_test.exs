if Application.compile_env(:needle_uid, :ulid_enabled, true) do
  if Code.ensure_loaded?(Uniq.UUID) do
    defmodule Needle.UID.ULIDSchemaTest do
      use ExUnit.Case, async: true

      alias Needle.UID
      alias Uniq.UUID

      defmodule TestSchema do
        use Ecto.Schema

        #  NOTE: no prefix defined here so it falls back to ULID
        @primary_key {:id, Needle.UID, autogenerate: true}
        @foreign_key_type Needle.UID

        schema "test" do
          belongs_to(:test, TestSchema)
        end
      end

      #  NOTE: no prefix defined here either
      @params UID.init(schema: TestSchema, field: :id, primary_key: true, autogenerate: true)
      @belongs_to_params UID.init(schema: TestSchema, field: :test, foreign_key: :test_id)
      @loader nil
      @dumper nil

      @test_ulid "3J6ASQVZ0K8K08W6WTB83Y4J91"
      @test_uuid UUID.to_string("7232b37d-fc13-44c0-8e1b-9a5a07e24921", :raw)
      @test_ulid_null "00000000000000000000000000"
      @test_uuid_null UUID.to_string("00000000-0000-0000-0000-000000000000", :raw)
      @test_ulid_invalid_characters String.duplicate(".", 26)
      @test_uuid_invalid_characters String.duplicate(".", 36)
      @test_ulid_invalid_format String.duplicate("x", 26)
      @test_uuid_invalid_format String.duplicate("x", 36)

      test "cast/2" do
        assert UID.cast(@test_ulid, @params) == {:ok, @test_ulid}
        assert UID.cast(@test_ulid_null, @params) == {:ok, @test_ulid_null}
        assert UID.cast(nil, @params) == {:ok, nil}
        assert {:error, _} = UID.cast("someprefix" <> @test_ulid, @params)
        assert {:error, _} = UID.cast(@test_ulid_invalid_characters, @params)
        assert {:error, _} = UID.cast(@test_ulid_invalid_format, @params)
        assert UID.cast(@test_ulid, @belongs_to_params) == {:ok, @test_ulid}

        assert {:error, _} = UID.cast("http://localhost/Erdman_Runolfsdottir", @params)
        refute UID.is_ulid?("http://localhost/Erdman_Runolfsdottir")
      end

      test "load/3" do
        assert UID.load(@test_uuid, @loader, @params) == {:ok, @test_ulid}
        assert UID.load(@test_uuid_null, @loader, @params) == {:ok, @test_ulid_null}

        # FIXME
        assert UID.load(@test_uuid_invalid_characters, @loader, @params) == :error

        assert UID.load(@test_uuid_invalid_format, @loader, @params) == :error
        assert UID.load(@test_ulid, @loader, @params) == :error
        assert UID.load(nil, @loader, @params) == {:ok, nil}
        assert UID.load(@test_uuid, @loader, @belongs_to_params) == {:ok, @test_ulid}
      end

      test "dump/3" do
        assert UID.dump(@test_ulid, @dumper, @params) == {:ok, @test_uuid}
        assert UID.dump(@test_ulid_null, @dumper, @params) == {:ok, @test_uuid_null}
        assert UID.dump(@test_uuid, @dumper, @params) == :error
        assert UID.dump(nil, @dumper, @params) == {:ok, nil}
        assert UID.dump(@test_ulid, @dumper, @belongs_to_params) == {:ok, @test_uuid}
      end

      test "generate/1 looks up the schema to determine what to generate" do
        ulid = Needle.UID.generate(TestSchema)

        assert Needle.UID.is_ulid?(ulid)
        refute Needle.UID.is_uuid?(ulid)
      end
    end
  end
end
