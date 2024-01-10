defmodule Redis do
  alias Redis.{Response, Store}

  @spec run([String.t()]) :: {:ok, Response.t()}
  def run(commands) do
    [command | args] = commands

    case [String.downcase(command) | args] do
      ["ping"] -> ping()
      ["echo", message] -> echo(message)
      ["set", key, value] -> set(key, value)
      ["get", key] -> get(key)
    end
  end

  defp ping() do
    {:ok, %Response{type: :simple_string, data: "PONG"}}
  end

  defp echo(data) do
    {:ok, %Response{type: :simple_string, data: data}}
  end

  defp set(key, value) do
    :ok = Store.set(key, value)
    {:ok, %Response{type: :simple_string, data: "OK"}}
  end

  defp get(key) do
    value = Store.get(key)
    {:ok, %Response{type: :bulk_string, data: value}}
  end
end
