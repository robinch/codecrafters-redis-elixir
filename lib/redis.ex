defmodule Redis do
  alias Redis.{Response, Store}
  alias Redis.Types.{Array, SimpleString, BulkString}
  require Logger

  def init() do
    Logger.debug("System args #{inspect(System.argv())}")
    handle_system_args(System.argv())
  end

  @spec run([String.t()]) :: {:ok, Response.t()}
  def run(commands) do
    [command | args] = commands

    case [String.upcase(command) | args] do
      ["PING"] ->
        ping()

      ["ECHO", message] ->
        echo(message)

      ["SET", key, value | options] ->
        set(key, value, to_set_opts(options))

      ["GET", key] ->
        get(key)

      ["CONFIG", command, key] ->
        case String.upcase(command) do
          "GET" -> config_get(key)
        end
    end
  end

  def ping() do
    {:ok, %Response{data: %SimpleString{data: "PONG"}}}
  end

  def echo(data) do
    {:ok, %Response{data: %SimpleString{data: data}}}
  end

  def set(key, value, opts) do
    :ok = Store.set(key, value)

    Enum.reduce(opts, :ok, fn
      {:px, expire_in_ms}, acc ->
        expire(key, expire_in_ms)
        acc
    end)

    {:ok, %Response{data: %SimpleString{data: "OK"}}}
  end

  def expire(key, expire_in_ms) do
    Task.Supervisor.start_child(
      Redis.TaskSupervisor,
      fn ->
        :timer.sleep(expire_in_ms)
        :ok = Store.delete(key)
      end,
      restart: :transient
    )
  end

  def get(key) do
    value = Store.get(key)
    {:ok, %Response{data: %BulkString{data: value}}}
  end

  @config_prefix "__config__"

  def config_set(key, value) do
    :ok = Store.set("#{@config_prefix}:#{key}", value)
    {:ok, %Response{data: %SimpleString{data: "OK"}}}
  end

  def config_get(key) do
    value = Store.get("#{@config_prefix}:#{key}")
    {:ok, %Response{data: %Array{data: [%BulkString{data: key}, %BulkString{data: value}]}}}
  end

  defp to_set_opts(options), do: do_to_set_opts(options, [])

  defp do_to_set_opts([], acc), do: Enum.reverse(acc)

  defp do_to_set_opts([opt | options], acc) do
    case String.upcase(opt) do
      "PX" ->
        [value | rest] = options
        do_to_set_opts(rest, [{:px, String.to_integer(value)} | acc])

      _ ->
        do_to_set_opts(options, acc)
    end
  end

  defp handle_system_args([]), do: :ok

  defp handle_system_args(["--dir", dir | rest]) do
    config_set("dir", dir)
    handle_system_args(rest)
  end

  defp handle_system_args(["--dbfilename", dir | rest]) do
    config_set("dbfilename", dir)
    handle_system_args(rest)
  end

  defp handle_system_args([_ | rest]) do
    handle_system_args(rest)
  end
end
