defmodule Needle.UID.TimestampTest do
  use ExUnit.Case, async: true

  alias Needle.UID

  # 0188a516-bc8c-7c5a-9b68-12651f558b9e -> 0x0188a516bc8c = 1686396910732 ms
  @uuid_v7 "0188a516-bc8c-7c5a-9b68-12651f558b9e"
  @uuid_v7_ms 1_686_396_910_732
  @uuid_v4 "7232b37d-fc13-44c0-8e1b-9a5a07e24921"

  test "extracts the embedded timestamp of a UUIDv7" do
    assert {:ok, @uuid_v7_ms} = UID.timestamp(@uuid_v7)

    assert DateTime.from_unix!(@uuid_v7_ms, :millisecond)
           |> DateTime.to_iso8601() == "2023-06-10T11:35:10.732Z"
  end

  test "accepts the raw 16-byte form" do
    {:ok, raw} = Ecto.UUID.dump(@uuid_v7)
    assert {:ok, @uuid_v7_ms} = UID.timestamp(raw)
  end

  test "rejects a UUID that is not version 7" do
    assert {:error, _} = UID.timestamp(@uuid_v4)
  end

  test "rejects malformed input" do
    assert {:error, _} = UID.timestamp("not-a-uuid")
    assert {:error, _} = UID.timestamp("")
  end

  if Application.compile_env(:needle_uid, :ulid_enabled, true) do
    # minted at the same instant as @uuid_v7, so both must report the same ms
    @ulid "01H2JHDF4CP8FCK4SMXPHW2N5J"

    test "still handles ULIDs, which encode the same 48-bit ms field" do
      assert {:ok, @uuid_v7_ms} = UID.timestamp(@ulid)
      assert UID.timestamp(@ulid) == UID.timestamp(@uuid_v7)
    end

    test "handles a freshly generated ULID" do
      assert {:ok, ms} = UID.timestamp(Needle.ULID.generate())
      assert_in_delta ms, System.system_time(:millisecond), 5_000
    end
  end
end
