defmodule Redis.Store do
  use GenServer

  @ets_name :store

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @callback get(key :: String.t()) :: String.t() | nil
  def get(key) do
    :ets.lookup(@ets_name, key)
    |> case do
      [{^key, value}] -> value
      [] -> nil
    end
  end

  @callback set(key :: String.t(), value :: String.t()) :: :ok
  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  @callback delete(key :: String.t()) :: :ok
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def init(_) do
    :ets.new(@ets_name, [:set, :protected, :named_table])
    {:ok, nil}
  end

  def handle_call({:set, key, value}, _from, state) do
    :ets.insert(@ets_name, {key, value})
    {:reply, :ok, state}
  end

  def handle_call({:delete, key}, _from, state) do
    :ets.delete(@ets_name, key)
    {:reply, :ok, state}
  end
end
