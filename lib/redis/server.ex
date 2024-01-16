defmodule Redis.Server do
  @moduledoc """
    Listens for incoming connections and starts a new connection process for each one.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    Redis.init()
    {:ok, listen_socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    {:ok, listen_socket, {:continue, :start_loop}}
  end

  def handle_continue(:start_loop, listen_socket) do
    send(self(), :listen)
    {:noreply, listen_socket}
  end

  def handle_info(:listen, listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    {:ok, pid} =
      DynamicSupervisor.start_child(Redis.ConnectionSupervisor, {Redis.Connection, socket})

    :ok = :gen_tcp.controlling_process(socket, pid)
    send(self(), :listen)
    {:noreply, listen_socket}
  end

  def terminate(_, listen_socket) do
    :gen_tcp.close(listen_socket)
  end
end
