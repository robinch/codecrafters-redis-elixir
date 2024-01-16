defmodule Redis.Types.BulkString do
  defstruct [:data]

  @type t :: %__MODULE__{data: String.t()}
end
