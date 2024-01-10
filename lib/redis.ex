defmodule Redis do
  alias Redis.{Response, Store}

  @spec run([String.t()]) :: {:ok, Response.t()}
  def run(commands) do
    [command | args] = commands

    case [String.upcase(command) | args] do
      ["PING"] -> ping()
      ["ECHO", message] -> echo(message)
      ["SET", key, value | options] -> set(key, value, to_set_opts(options))
      ["GET", key] -> get(key)
    end
  end

  def ping() do
    {:ok, %Response{type: :simple_string, data: "PONG"}}
  end

  def echo(data) do
    {:ok, %Response{type: :simple_string, data: data}}
  end

  def set(key, value, opts) do
    :ok = Store.set(key, value)

    Enum.reduce(opts, :ok, fn
      {:px, expire_in_ms}, acc ->
        expire(key, expire_in_ms)
        acc
    end)

    {:ok, %Response{type: :simple_string, data: "OK"}}
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
    {:ok, %Response{type: :bulk_string, data: value}}
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
end
