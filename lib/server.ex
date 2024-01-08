defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    {:ok, l_socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    {:ok, socket} = :gen_tcp.accept(l_socket)
    {:ok, _data} = :gen_tcp.recv(socket, 0)
    :ok = :gen_tcp.send(socket, "+PONG\r\n")
  end
end
