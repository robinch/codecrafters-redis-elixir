defmodule Redis.Rdb.Database do
  defstruct [:db_number, key_value_pairs: []]
  alias Redis.Rdb.KeyValuePair

  @type t :: %__MODULE__{
          db_number: non_neg_integer(),
          key_value_pairs: list(KeyValuePair.t())
        }
end
