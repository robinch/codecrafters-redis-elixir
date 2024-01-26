defmodule Redis.Response do
  defstruct [:data]

  @type redis_types ::
          Redis.Types.BulkString.t()
          | Redis.Types.SimpleString.t()
          | Redis.Types.Array.t()
  @type t :: %__MODULE__{data: redis_types()}
end
