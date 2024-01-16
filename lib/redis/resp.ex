defmodule Redis.RESP do
  alias Redis.Response
  alias Redis.Types.{Array, BulkString, SimpleString}
  require Logger

  def encode(data) do
    case data do
      %Response{data: data} ->
        encode(data)

      %SimpleString{data: data} ->
        simple_string(data)

      %BulkString{data: data} ->
        bulk_string(data)

      %Array{data: data} ->
        array(data)

      data ->
        Logger.error("Could not encode #{data}")
        {:error, "Could not encode #{data}"}
    end
  end

  def simple_string(string) do
    {:ok, "+#{string}\r\n"}
  end

  def bulk_string(nil) do
    {:ok, "$-1\r\n"}
  end

  def bulk_string(string) do
    length = String.length(string)
    {:ok, "$#{length}\r\n#{string}\r\n"}
  end

  def array(elements) do
    length = Enum.count(elements)

    encoded_elements =
      Enum.map(
        elements,
        fn element ->
          {:ok, elem} = encode(element)
          elem
        end
      )
      |> Enum.join()

    {:ok, "*#{length}\r\n#{encoded_elements}"}
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
