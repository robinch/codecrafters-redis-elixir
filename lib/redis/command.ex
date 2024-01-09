defmodule Redis.Command do
alias Redis.Type.SimpleString
  def ping() do
    {:ok, %SimpleString{data: "PONG"}}
  end

  def echo(data) do
    {:ok, %SimpleString{data: data}}
  end
end
