defmodule Redis.Response do
 defstruct [:type, :data]

  @type type :: :simple_string
  @type t :: %__MODULE__{type: type, data: String.t()}
end
