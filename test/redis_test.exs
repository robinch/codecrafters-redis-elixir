defmodule RedisTest do
  use ExUnit.Case

  alias Redis.Type.SimpleString

  describe "run" do
    test "ping" do
      assert {:ok, %Redis.Response{type: :simple_string, data: "PONG"}} == Redis.run(["ping"])
    end

    test "ECHO" do
      assert {:ok, %Redis.Response{type: :simple_string, data: "hey"}} == Redis.run(["ECHO", "hey"])
    end
  end

  test "ping" do
    assert {:ok, %Redis.Response{type: :simple_string, data: "PONG"}} == Redis.ping()
  end

  test "echo" do
    assert {:ok, %Redis.Response{type: :simple_string, data: "hello"}} == Redis.echo("hello")
  end
end
