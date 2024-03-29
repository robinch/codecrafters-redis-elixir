defmodule Redis.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Redis.TaskSupervisor},
      Redis.Store,
      Redis.Server,
      {DynamicSupervisor, name: Redis.ConnectionSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Redis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
