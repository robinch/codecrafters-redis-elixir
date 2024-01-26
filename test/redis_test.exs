defmodule RedisTest do
  use ExUnit.Case

  alias Redis.Types.{BulkString, SimpleString}

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
    end

    test "get" do
      {:ok, _} = Redis.run(["SET", "beans", "healthy"])

      assert {:ok, %Redis.Response{data: %BulkString{data: "healthy"}}} ==
               Redis.run(["GET", "beans"])
    end

    test "configs" do
      {:ok, _} = Redis.config_set("dir", "test/support/")
      {:ok, _} = Redis.config_set("dbfilename", "test.rdb")

      assert {:ok,
              %Redis.Response{
                data: %Redis.Types.Array{
                  data: [
                    %Redis.Types.BulkString{data: "dir"},
                    %Redis.Types.BulkString{data: "test/support/"}
                  ]
                }
              }} == Redis.run(["CONFIG", "GET", "dir"])

      assert {:ok, "test/support/test.rdb"} == Redis.filepath_from_config()

      :ok = Redis.Rdb.load_from_file("test/support/test.rdb")

      assert {:ok, %Redis.Response{type: nil, data: %Redis.Types.BulkString{data: "myval"}}} == Redis.run(["GET", "mykey"])
    end
  end
end
