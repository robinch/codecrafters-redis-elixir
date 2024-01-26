defmodule Redis.Rdb.KeyValuePair do
  defstruct [:key, :value]

  @type t :: %__MODULE__{
          key: binary(),
          value: binary()
        }
end
