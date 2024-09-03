defmodule Needle.UID.UlidTest do
  use ExUnit.Case, async: true

  @binary <<1, 95, 194, 60, 108, 73, 209, 114, 136, 236, 133, 115, 106, 195, 145, 22>>
  @encoded "01BZ13RV29T5S8HV45EDNC748P"

  # generate/0


  test "generate/1 encodes a timestamp" do
    {:ok, utc_date, _} = DateTime.from_iso8601("2015-02-10T15:00:00Z")

    timestamp = DateTime.to_unix(utc_date)

    ulid = Needle.UID.generate(timestamp)

    {:ok, encoded_ts} = Needle.UID.timestamp(ulid)

    assert encoded_ts == timestamp
  end

  test "generate/0 generates unique identifiers" do
    ulid1 = Needle.UID.generate()
    ulid2 = Needle.UID.generate()

    assert ulid1 != ulid2
  end


  # cast/1

  test "cast/1 returns valid UID" do
    {:ok, ulid} = Needle.UID.cast(@encoded)
    assert ulid == @encoded
  end

  test "cast/1 returns UID for encoding of correct length" do
    {:ok, ulid} = Needle.UID.cast("00000000000000000000000000")
    assert ulid == "00000000000000000000000000"
  end

  test "cast/1 returns error when encoding is too short" do
    assert {:error, _} = Needle.UID.cast("0000000000000000000000000") 
  end

  test "cast/1 returns error when encoding is too long" do
    assert {:error, _} = Needle.UID.cast("000000000000000000000000000") 
  end

  test "cast/1 returns error when encoding contains letter I" do
    assert {:error, _} = Needle.UID.cast("I0000000000000000000000000") 
  end

  test "cast/1 returns error when encoding contains letter L" do
    assert {:error, _} = Needle.UID.cast("L0000000000000000000000000")
  end

  test "cast/1 returns error when encoding contains letter O" do
    assert {:error, _} =  Needle.UID.cast("O0000000000000000000000000") 
  end

  test "cast/1 returns error when encoding contains letter U" do
    assert {:error, _} = Needle.UID.cast("U0000000000000000000000000") 
  end

  test "cast/1 returns error for invalid encoding" do
    assert {:error, _} = Needle.UID.cast("$0000000000000000000000000") 
  end

  # dump/1

  test "dump/1 dumps valid UID to binary" do
    {:ok, bytes} = Needle.UID.dump(@encoded)
    assert bytes == @binary
  end

  test "dump/1 dumps encoding of correct length" do
    {:ok, bytes} = Needle.UID.dump("00000000000000000000000000")
    assert bytes == <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  end

  test "dump/1 returns error when encoding is too short" do
    assert Needle.UID.dump("0000000000000000000000000") == :error
  end

  test "dump/1 returns error when encoding is too long" do
    assert Needle.UID.dump("000000000000000000000000000") == :error
  end

  test "dump/1 returns error when encoding contains letter I" do
    assert Needle.UID.dump("I0000000000000000000000000") == :error
  end

  test "dump/1 returns error when encoding contains letter L" do
    assert Needle.UID.dump("L0000000000000000000000000") == :error
  end

  test "dump/1 returns error when encoding contains letter O" do
    assert Needle.UID.dump("O0000000000000000000000000") == :error
  end

  test "dump/1 returns error when encoding contains letter U" do
    assert Needle.UID.dump("U0000000000000000000000000") == :error
  end

  test "dump/1 returns error for invalid encoding" do
    assert Needle.UID.dump("$0000000000000000000000000") == :error
  end

  # load/1

  test "load/1 encodes binary as UID" do
    {:ok, encoded} = Needle.UID.load(@binary)
    assert encoded == @encoded
  end

  test "load/1 encodes binary of correct length" do
    {:ok, encoded} = Needle.UID.load(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)

    assert encoded == "00000000000000000000000000"
  end

  test "load/1 returns error when data is too short" do
    assert Needle.UID.load(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>) ==
             :error
  end

  test "load/1 returns error when data is too long" do
    assert Needle.UID.load(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>) == :error
  end
end
