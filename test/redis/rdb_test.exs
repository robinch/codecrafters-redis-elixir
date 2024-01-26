defmodule Redis.RdbTest do
  use ExUnit.Case, async: false
  alias Redis.Rdb

  # hexdump -C test/support/test.rdb
  # 00000000  52 45 44 49 53 30 30 31  31 fa 09 72 65 64 69 73  |REDIS0011..redis|
  # 00000010  2d 76 65 72 05 37 2e 32  2e 34 fa 0a 72 65 64 69  |-ver.7.2.4..redi|
  # 00000020  73 2d 62 69 74 73 c0 40  fa 05 63 74 69 6d 65 c2  |s-bits.@..ctime.|
  # 00000030  cc f7 a7 65 fa 08 75 73  65 64 2d 6d 65 6d c2 18  |...e..used-mem..|
  # 00000040  d1 0e 00 fa 08 61 6f 66  2d 62 61 73 65 c0 00 fe  |.....aof-base...|
  # 00000050  00 fb 01 00 00 05 6d 79  6b 65 79 05 6d 79 76 61  |......mykey.myva|
  # 00000060  6c ff 4e d0 31 e9 29 8f  0e 6b                    |l.N.1.)..k|
  # 0000006a

  setup do
    filepath = "test/support/test.rdb"

    one_key_rdb =
      filepath
      |> File.open!([:read, :binary])
      |> IO.binread(:eof)

    {:ok, %{one_key_rdb: one_key_rdb, filepath: filepath}}
  end

  test "load_from_file", %{filepath: filepath} do
    {:ok, _} = Redis.FakeStore.start_link([])

    assert :ok == Rdb.load_from_file(filepath, Redis.FakeStore)
    assert "myval" == Redis.FakeStore.get("mykey")
  end

  test "parse", %{one_key_rdb: rdb} do
    assert {:ok, rdb} = Rdb.parse(rdb)

    assert %Rdb{
             rdb_version: 11,
             hash_table_size: 1,
             expire_hash_table_size: 0,
             databases: [
               %Redis.Rdb.Database{
                 db_number: 0,
                 key_value_pairs: [%Redis.Rdb.KeyValuePair{key: "mykey", value: "myval"}]
               }
             ]
           } == rdb
  end

  test "invalid magic string" do
    assert {:error, :invalid_magic_string} = Rdb.validate_header(<<?R, ?O, ?B, ?I, ?N, ?!>>)
  end

  test "skip aux field" do
    assert {:ok, <<0xFE, 0x03, 0x04>>} == Rdb.skip_aux_field(<<0x01, 0x02, 0xFE, 0x03, 0x04>>)
  end

  describe "parse string" do
    test "with 0b00" do
      rest = 0b00001111

      assert {:ok, "robin", <<rest>>} ==
               Rdb.parse_string(<<0b00::size(2), 0b000101::size(6), ?r, ?o, ?b, ?i, ?n, rest>>)
    end

    test "with 0b01" do
      rest = 0b00001111

      assert {:ok, "robin", <<rest>>} ==
               Rdb.parse_string(
                 <<0b01::size(2), 0b000000::size(6), 0x05, ?r, ?o, ?b, ?i, ?n, rest>>
               )
    end

    test "with 0b10" do
      rest = 0b00001111

      assert {:ok, "robin", <<rest>>} ==
               Rdb.parse_string(
                 <<0b10::size(2), 0b000000::size(6), 0x00, 0x00, 0x00, 0x05, ?r, ?o, ?b, ?i, ?n,
                   rest>>
               )
    end
  end

  # describe "parse integer" do
  #   test "with 0b00" do
  #     rest = 0b00001111
  #
  #     assert {:ok, 5, <<rest>>} ==
  #              Rdb.parse_integer(<<0b11::size(2), 0b000000::size(6), 0x05, rest>>)
  #   end
  #
  #   test "with 0b01" do
  #     rest = 0b00001111
  #
  #     assert {:ok, 5, <<rest>>} ==
  #              Rdb.parse_integer(<<0b11::size(2), 0b000001::size(6), 0x00, 0x05, rest>>)
  #   end
  #
  #   test "with 0b10" do
  #     rest = 0b00001111
  #
  #     assert {:ok, 5, <<rest>>} ==
  #              Rdb.parse_integer(<<0b11::size(2), 0b000010::size(6), 0x00, 0x00, 0x00, 0x05, rest>>)
  #   end
  # end
end
