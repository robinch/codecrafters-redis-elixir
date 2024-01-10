defmodule RedisTest do
  use ExUnit.Case

  describe "run" do
    test "ping" do
      assert {:ok, %Redis.Response{type: :simple_string, data: "PONG"}} == Redis.run(["ping"])
    end

    test "echo" do
      assert {:ok, %Redis.Response{type: :simple_string, data: "hey"}} ==
               Redis.run(["ECHO", "hey"])
    end

    test "set" do
      assert {:ok, %Redis.Response{type: :simple_string, data: "OK"}} ==
               Redis.run(["SET", "city", "Stockholm"])
    end

    test "get" do
      {:ok, _} = Redis.run(["SET", "beans", "healthy"])

      assert {:ok, %Redis.Response{type: :bulk_string, data: "healthy"}} ==
               Redis.run(["GET", "beans"])
    end
  end
end
