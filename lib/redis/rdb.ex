defmodule Redis.Rdb do
  defstruct [:rdb_version, :hash_table_size, :expire_hash_table_size, databases: []]

  alias Redis.Rdb.{Database, KeyValuePair}

  require Logger

  @type t :: %__MODULE__{
          rdb_version: Integer.t(),
          hash_table_size: Integer.t(),
          expire_hash_table_size: Integer.t(),
          databases: [Database.t()]
        }

  def load_from_file(file_path, store \\ Redis.Store) do
    with {:ok, binary} <- File.read(file_path),
         {:ok, rdb} <- parse(binary) do
      Enum.each(rdb.databases, fn db ->
        Logger.info(
          "Loading DB #{db.db_number} with #{length(db.key_value_pairs)} key-value pairs"
        )

        Enum.each(db.key_value_pairs, fn %KeyValuePair{key: key, value: value} ->
          Logger.debug("Storing key #{inspect(key)} with value #{inspect(value)} from rdb file")
          store.set(key, value)
        end)
      end)

      :ok
    else
      {:error, reason} ->
        Logger.error("Could not read file #{file_path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def parse(binary) do
    rdb = %__MODULE__{}

    with {:ok, rest} <- validate_header(binary),
         {:ok, rdb, rest} = parse_rdb_version(rdb, rest),
         {:ok, rest} = skip_aux_field(rest),
         {:ok, rdb, _rest} = parse_db(rdb, rest) do
      {:ok, rdb}
    end
  end

  def validate_header(<<?R, ?E, ?D, ?I, ?S, rest::binary>>) do
    {:ok, rest}
  end

  def validate_header(_), do: {:error, :invalid_magic_string}

  def parse_rdb_version(rdb = %__MODULE__{}, <<rdb_version::binary-size(4), rest::binary>>) do
    rdb = %{rdb | rdb_version: String.to_integer(rdb_version)}

    {:ok, rdb, rest}
  end

  def skip_aux_field(<<0xFE, _::binary>> = rest), do: {:ok, rest}

  def skip_aux_field(<<_::binary-size(1), rest::binary>>) do
    skip_aux_field(rest)
  end

  def parse_db(rdb = %__MODULE__{}, <<0xFF, rest::binary>>) do
    {:ok, rdb, rest}
  end

  def parse_db(rdb = %__MODULE__{}, <<0xFE, db_number::unsigned-size(8), rest::binary>>) do
    {:ok, hash_table_size, expire_hash_table_size, rest} = parse_resizedb_field(rest)

    rdb = %{
      rdb
      | hash_table_size: hash_table_size,
        expire_hash_table_size: expire_hash_table_size
    }

    db = %Database{db_number: db_number}
    {:ok, db, rest} = parse_key_value_pairs(db, rest)

    rdb = %{rdb | databases: [db | rdb.databases]}
    parse_db(rdb, rest)
  end

  def parse_resizedb_field(<<0xFB, rest::binary>>) do
    with {:ok, hash_table_size, rest} <- parse_length(rest),
         {:ok, expire_hash_table_size, rest} <- parse_length(rest) do
      {:ok, hash_table_size, expire_hash_table_size, rest}
    end
  end

  # Right now I assume that there is only one DB and one key value pair.
  # So I finish reading key value pairs when I get the end of RDB indicator (0xFF).

  # This will stop the parsing at the end of RDB indicator (0xFF)
  # I don't need this just yet
  # def parse_key_value_pairs(rdb, db, <<0xFF, _checksum::binary>> = rest) do
  #   {:ok, rdb, db, rest}
  # end

  # TODO: Support key-value pairs with expiry
  # def parse_key_value_pairs(
  #       rdb,
  #       db,
  #       <<0xFD, expiry_in_seconds::unsigned-size(4), value_type::binary-size(1),
  #         kv_pair_and_rest::binary>>
  #     ) do
  # end

  # def parse_key_value_pairs(
  #       rdb,
  #       db,
  #       <<0xFD, expiry_in_milliseconds::unsigned-size(8), value_type::binary-size(1),
  #         kv_pair_and_rest::binary>>
  #     ) do
  # end

  def parse_key_value_pairs(db = %Database{}, <<0xFE, _::binary>> = rest) do
    {:ok, db, rest}
  end

  def parse_key_value_pairs(db = %Database{}, <<0xFF, _::binary>> = rest) do
    {:ok, db, rest}
  end

  def parse_key_value_pairs(
        db = %Database{},
        <<_value_type::integer-size(8), kv_pair_and_rest::binary>>
      ) do
    {:ok, key, val_and_rest} = parse_string(kv_pair_and_rest)

    # TODO: Parse value correctly, now just assumes it's a string
    {:ok, val, rest} = parse_string(val_and_rest)

    kvp = %KeyValuePair{key: key, value: val}

    db = %{db | key_value_pairs: [kvp | db.key_value_pairs]}

    parse_key_value_pairs(db, rest)
  end

  # Not needed yet
  # def value_type(value_type) do
  #   case value_type do
  #     0 -> :string
  #     1 -> :list
  #     2 -> :set
  #     3 -> :sorted_set
  #     4 -> :hash 9 -> :zipmap 10 -> :ziplist
  #     11 -> :intset
  #     12 -> :sorted_set_in_ziplist
  #     13 -> :hashmap_in_ziplist
  #     14 -> :list_in_quicklist
  #   end
  # end

  def parse_length(<<0b00::size(2), length::size(6), rest::binary>>) do
    {:ok, length, rest}
  end

  def parse_length(<<0b01::size(2), length::size(14), rest::binary>>) do
    {:ok, length, rest}
  end

  def parse_length(<<0b10::size(2), _::size(6), length::size(32), rest::binary>>) do
    {:ok, length, rest}
  end

  def parse_length(<<0b11::size(2), _::binary>> = rest) do
    Logger.error("Special format not supported yet")
    {:error, :special_form_not_supported, rest}
  end

  def parse_string(binary) do
    {:ok, length, rest} = parse_length(binary)

    <<key::binary-size(length), rest::binary>> = rest
    {:ok, key, rest}
  end
end
