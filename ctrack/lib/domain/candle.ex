defmodule Domain.Candle do
  @moduledoc """
  Структура для хранения данных свечи и функции преобразования.
  """

  defstruct [
    :figi,
    :instrument_uid,
    :instrument_name,
    :prices,
    :time,
    :last_trade_ts,
    :volume
  ]

  @type t :: %__MODULE__{
          figi: String.t(),
          instrument_uid: String.t(),
          instrument_name: String.t(),
          prices: %{
            open: float(),
            close: float(),
            high: float(),
            low: float()
          },
          time: DateTime.t(),
          last_trade_ts: DateTime.t(),
          volume: integer()
        }

  @doc """
  Преобразует raw данные от API в структуру свечи.

  ## Examples
      iex> raw_data = %{
        "figi" => "BBG004730RP0",
        "instrumentUid" => "962e2a95-02a9-4171-abd7-aa198dbe643a",
        "open" => %{"units" => "170", "nano" => 310000000},
        "close" => %{"units" => "170", "nano" => 300000000},
        "high" => %{"units" => "170", "nano" => 310000000},
        "low" => %{"units" => "170", "nano" => 300000000},
        "volume" => "208",
        "time" => "2025-02-23T18:43:00Z",
        "lastTradeTs" => "2025-02-23T18:43:09.088632741Z"
      }
      iex> Tbank.Candle.from_raw(raw_data)
      {:ok, %Tbank.Candle{...}}
  """
  def from_raw(raw) when is_map(raw) do
    with {:ok, open} <- parse_price(raw["open"]),
         {:ok, close} <- parse_price(raw["close"]),
         {:ok, high} <- parse_price(raw["high"]),
         {:ok, low} <- parse_price(raw["low"]),
         {:ok, volume} <- parse_volume(raw["volume"]),
         {:ok, time} <- parse_datetime(raw["time"]),
         {:ok, last_trade_ts} <- parse_datetime(raw["lastTradeTs"]) do
      candle = %__MODULE__{
        figi: raw["figi"],
        instrument_uid: raw["instrumentUid"],
        instrument_name: raw["instrumentName"] || get_instrument_name(raw["figi"]),
        prices: %{
          open: open,
          close: close,
          high: high,
          low: low
        },
        time: time,
        last_trade_ts: last_trade_ts,
        volume: volume
      }

      {:ok, candle}
    else
      error -> {:error, error}
    end
  end

  def from_raw(_), do: {:error, :invalid_data}

  @doc """
  Преобразует цену из формата Tinkoff (units + nano) в float.
  """
  def parse_price(%{"units" => units, "nano" => nano}) when is_binary(units) do
    case Integer.parse(units) do
      {units_int, ""} ->
        {:ok, units_int + nano / 1_000_000_000}

      _ ->
        {:error, :invalid_price_format}
    end
  end

  def parse_price(_), do: {:error, :invalid_price_data}

  @doc """
  Преобразует объем из строки в integer.
  """
  def parse_volume(volume) when is_binary(volume) do
    case Integer.parse(volume) do
      {volume_int, ""} -> {:ok, volume_int}
      _ -> {:error, :invalid_volume_format}
    end
  end

  def parse_volume(_), do: {:error, :invalid_volume_data}

  @doc """
  Преобразует строку времени в DateTime.
  """
  def parse_datetime(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _offset} -> {:ok, dt}
      error -> error
    end
  end

  def parse_datetime(_), do: {:error, :invalid_datetime}

  @doc """
  Получает название инструмента по FIGI.
  Здесь вы можете реализовать кэширование или загрузку из базы данных.
  """
  def get_instrument_name(figi) do
    # TODO: Implement instrument name lookup
    figi
  end
end
