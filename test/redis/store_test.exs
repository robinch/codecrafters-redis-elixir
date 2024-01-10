defmodule Redis.StoreTest do
  use ExUnit.Case

  test "store and get" do
    assert :ok = Redis.Store.set("k", "v")
    assert "v" == Redis.Store.get("k")
  end

  test "get non-existent key" do
    assert nil == Redis.Store.get("non-existent-key")
  end
end
