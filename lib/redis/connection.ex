defmodule Redis.Connection do
  @moduledoc """
    Handles and takes over a new connection to a client.
  """
  use GenServer
  require Logger
  alias Redis.RESP

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:ok, %{socket: socket}, {:continue, :start_loop}}
  end

  def handle_continue(:start_loop, state) do
    Logger.debug("handle_continue in Connection called")
    send(self(), :listen)
    {:noreply, state}
  end

  def handle_info(:listen, state) do
    Logger.debug("handle_info :listen in Connection called")
    {:ok, data} = :gen_tcp.recv(state.socket, 0)

    {:ok, result} =
      data
      |> RESP.decode()
      |> Redis.run()

    {:ok, response} = RESP.encode(result)

    :ok = :gen_tcp.send(state.socket, response)
    send(self(), :listen)
    {:noreply, state}
  end

  def terminate(_reason, state) do
    :gen_tcp.close(state.socket) 
  end
end
