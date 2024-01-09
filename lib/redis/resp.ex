defmodule Redis.RESP do

  alias Redis.Type

  def encode(result)do
    case result do
      %Type.SimpleString{data: data} -> simple_string(data)
    end
  end

  def simple_string(string) do
    {:ok, "+#{string}\r\n"}
  end

  def decode(resp) do
    elements = String.split(resp, "\r\n", trim: true)
    unpack(elements, [])
  end

  defp unpack([], acc), do: Enum.reverse(acc)

  defp unpack([elem | elements], acc) do
    {type, length} = parse_request_data_type(elem)

    case type do
      :bulk_string ->
        {collected_string, rest} = parse_bulk_string(elements, length)
        unpack(rest, [collected_string | acc])

      _ ->
        unpack(elements, acc)
    end
  end

  @spec parse_bulk_string([String.t()], integer()) :: {String.t(), [String.t()]}
  def parse_bulk_string(elements, len) do
    do_parse_bulk_string(elements, len, "")
  end

  defp do_parse_bulk_string(elements, 0, acc), do: {acc, elements}

  defp do_parse_bulk_string([elem | elements], len, acc) do
    do_parse_bulk_string(elements, len - String.length(elem), acc <> elem)
  end

  def parse_request_data_type(<<type::size(8), len::binary>>) do
    data_type =
      case type do
        ?+ -> :simple_string
        ?* -> :array
        ?$ -> :bulk_string
        ?: -> :integer
      end

    length =
      case len do
        "" -> 0
        n -> String.to_integer(n)
      end

    {data_type, length}
  end
end
