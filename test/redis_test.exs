defmodule RedisTest do
  use ExUnit.Case

  alias Redis.Type.SimpleString

  describe "run" do
    test "ping" do
      assert {:ok, %SimpleString{data: "PONG"}} == Redis.run(["ping"])
    end

    test "ECHO" do
      assert {:ok, %SimpleString{data: "hey"}} == Redis.run(["ECHO", "hey"])
    end
  end
end
