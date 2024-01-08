defmodule Redis.Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    {:ok, listen_socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    send(self(), :listen)
    {:ok, %{socket: socket, listen_socket: listen_socket}}
  end

  def handle_info(:listen, %{socket: socket} = state) do
    {:ok, _data} = :gen_tcp.recv(socket, 0)
    :ok = :gen_tcp.send(socket, "+PONG\r\n")
    send(self(), :listen)
    {:noreply, state}
  end
end
