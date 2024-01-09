defmodule Redis.Server do
  @moduledoc """
    Listens for incoming connections and starts a new connection process for each one.
  """
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    {:ok, listen_socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    {:ok, %{listen_socket: listen_socket}, {:continue, :start_loop}}
  end

  def handle_continue(:start_loop, state) do
    Logger.debug("handle_continue in Server called")
    send(self(), :listen)
    {:noreply, state}
  end

  def handle_info(:listen, %{listen_socket: listen_socket} = state) do
    Logger.debug("handle_info :listen in Server called")
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    {:ok, pid} =
      DynamicSupervisor.start_child(Redis.ConnectionSupervisor, {Redis.Connection, socket})

    :ok = :gen_tcp.controlling_process(socket, pid)
    send(self(), :listen)
    {:noreply, state}
  end
end
