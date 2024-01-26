defmodule RedisTest do
  use ExUnit.Case, async: false

  alias Redis.Types.{Array, BulkString, SimpleString}

  describe "run" do
    test "ping" do
      assert {:ok, %Redis.Response{data: %SimpleString{data: "PONG"}}} == Redis.run(["ping"])
    end

    test "echo" do
      assert {:ok, %Redis.Response{data: %SimpleString{data: "hey"}}} ==
               Redis.run(["ECHO", "hey"])
    end

    test "set" do
      assert {:ok, %Redis.Response{data: %SimpleString{data: "OK"}}} ==
               Redis.run(["SET", "city", "Stockholm"])

      :ok = Redis.Store.delete("city")
    end

    test "get" do
      {:ok, _} = Redis.run(["SET", "beans", "healthy"])

      assert {:ok, %Redis.Response{data: %BulkString{data: "healthy"}}} ==
               Redis.run(["GET", "beans"])

      :ok = Redis.Store.delete("beans")
    end

    test "configs" do
      {:ok, _} = Redis.config_set("dir", "test/support")
      {:ok, _} = Redis.config_set("dbfilename", "test.rdb")

      assert {:ok,
              %Redis.Response{
                data: %Redis.Types.Array{
                  data: [
                    %Redis.Types.BulkString{data: "dir"},
                    %Redis.Types.BulkString{data: "test/support"}
                  ]
                }
              }} == Redis.run(["CONFIG", "GET", "dir"])

      assert {:ok, "test/support/test.rdb"} == Redis.filepath_from_config()

      :ok = Redis.Rdb.load_from_file("test/support/test.rdb")

      assert {:ok, %Redis.Response{data: %Redis.Types.BulkString{data: "myval"}}} ==
               Redis.run(["GET", "mykey"])

      :ok = Redis.Store.delete("mykey")
    end

    test "keys" do
      {:ok, _} = Redis.run(["SET", "key1", "1"])
      {:ok, _} = Redis.run(["SET", "key2", "2"])

      assert {:ok, %Redis.Response{data: %Array{data: data}}} = Redis.run(["keys", "*"])

      assert length(data) == 2

      keys = Enum.map(data, fn %BulkString{data: key} -> key end)

      assert Enum.member?(keys, "key1")
      assert Enum.member?(keys, "key2")
    end
  end
end
