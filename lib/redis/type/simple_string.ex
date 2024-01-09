defmodule Redis.Type.SimpleString do
  defstruct [:data]
  @type t :: %__MODULE__{data: String.t()}
end
