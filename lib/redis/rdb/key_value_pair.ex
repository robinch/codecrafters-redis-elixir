defmodule Redis.Rdb.KeyValuePair do
  defstruct [:key, :value, :expires_at]

  @type t :: %__MODULE__{
          key: binary(),
          value: binary(),
          expires_at: DateTime.t() | nil
        }
end
