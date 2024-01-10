defmodule Redis do
  alias Redis.Response

  @spec run([String.t()]) :: {:ok, Response.t()}
  def run(commands) do
    [command | args] = commands

    case [String.downcase(command) | args] do
      ["ping"] -> ping()
      ["echo", message] -> echo(message)
    end
  end

  def ping() do
    {:ok, %Response{type: :simple_string, data: "PONG"}}
  end

  def echo(data) do
    {:ok, %Response{type: :simple_string, data: data}}
  end
end
