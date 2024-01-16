defmodule Redis.Types.Array do
  defstruct [:data]

  @type redis_types :: Redis.Types.BulkString.t() | Redis.Types.SimpleString.t()
  @type t :: %__MODULE__{data: [redis_types()]}
end
