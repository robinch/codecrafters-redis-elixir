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

    test "get config" do
      {:ok, _} = Redis.config_set("dir", "/tmp/test_dir/")

      assert {:ok,
              %Redis.Response{
                data: %Redis.Types.Array{
                  data: [
                    %Redis.Types.BulkString{data: "dir"},
                    %Redis.Types.BulkString{data: "/tmp/test_dir/"}
                  ]
                }
              }} == Redis.run(["CONFIG", "GET", "dir"])
    end
  end
end
