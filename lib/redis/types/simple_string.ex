defmodule Redis.Types.SimpleString do
  defstruct [:data]

  @type t :: %__MODULE__{data: String.t()}
end
