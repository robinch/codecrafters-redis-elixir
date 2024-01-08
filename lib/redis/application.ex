defmodule Redis.Application do
  use Application

  def start(_type, _args) do
    children = [Redis.Server]

    opts = [strategy: :one_for_one, name: Redis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
