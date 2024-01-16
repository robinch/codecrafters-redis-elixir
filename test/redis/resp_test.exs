defmodule Redis.RespTest do
  use ExUnit.Case
  alias Redis.RESP

  alias Redis.Response
  alias Redis.Types.{Array, BulkString}

  describe "decode" do
    test "ECHO" do
      ["ECHO", "hey"] = RESP.decode("*2\r\n$4\r\nECHO\r\n$3\r\nhey\r\n")
    end

    test "PING" do
      ["ping"] = RESP.decode("*1\r\n$4\r\nping\r\n")
    end
  end

  test "parse_request_data_type" do
    assert {:array, 2} = RESP.parse_request_data_type("*2")
  end

  test "collect bulk string" do
    {"ECHO", ["HEL", "LO"]} = RESP.parse_bulk_string(["EC", "HO", "HEL", "LO"], 4)
  end

  describe "encode" do
    test "array" do
      assert {:ok, "*2\r\n$3\r\ndir\r\n$16\r\n/tmp/redis-files\r\n"} =
               RESP.encode(%Response{
                 data: %Array{
                   data: [
                     %BulkString{data: "dir"},
                     %BulkString{data: "/tmp/redis-files"}
                   ]
                 }
               })
    end
  end
end
