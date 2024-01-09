defmodule Redis do
  def run(commands) do
    [command | args] = commands

    case [String.downcase(command) | args] do
      ["ping"] -> Redis.Command.ping()
      ["echo", message] -> Redis.Command.echo(message)
    end
  end
end
