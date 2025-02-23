defmodule Tbank.Websocket do
  use WebSockex
  require Logger

  @tbank_ws_addr "wss://invest-public-api.tinkoff.ru/ws"

  def start_link(options) do
    extra_headers = [
      {"Authorization", "Bearer " <> Application.get_env(:ctrack, :tbank_token)},
      {"Web-Socket-Protocol", "json"}
    ]

    addr = "tinkoff.public.invest.api.contract.v1.MarketDataStreamService/MarketDataStream"

    instruments = Application.get_env(:ctrack, :instruments)

    {:ok, pid} =
      WebSockex.start_link("#{@tbank_ws_addr}/#{addr}", __MODULE__, options,
        extra_headers: extra_headers
      )

    WebSockex.send_frame(pid, {:text, Jason.encode!(subscribe_message(instruments))})

    {:ok, pid}
  end

  def handle_connect(_, state) do
    Logger.info("Connected to Tinkoff WebSocket")
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode!(msg) do
      %{"candle" => candle} ->
        handle_candle_data(candle, state)
        {:ok, state}

      %{"error" => error} ->
        Logger.error("Received error from Tinkoff: #{inspect(error)}")
        {:ok, state}

      msg ->
        Enum.each(
          msg["subscribeCandlesResponse"]["candlesSubscriptions"],
          fn %{"figi" => figi, "subscriptionStatus" => status} ->
            Jason.encode!(%{
              message: "Received message",
              figi: figi,
              subscriptionStatus: status
            })
            |> Logger.debug()
          end
        )

        {:ok, state}
    end
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("Disconnected from Tinkoff: #{inspect(reason)}")
    {:reconnect, state}
  end

  defp subscribe_message(instruments) do
    %{
      "subscribeCandlesRequest" => %{
        "subscriptionAction" => "SUBSCRIPTION_ACTION_SUBSCRIBE",
        "instruments" =>
          Enum.map(
            instruments,
            fn instrument ->
              instrument
              |> Map.drop([:name, :color])
              |> Map.put(:interval, "SUBSCRIPTION_INTERVAL_ONE_MINUTE")
            end
          ),
        "waitingClose" => false
      }
    }
  end

  defp handle_candle_data(candle, _) do
    case Domain.Candle.from_raw(candle) do
      {:ok, processed_candle} ->
        Phoenix.PubSub.broadcast(
          Ctrack.PubSub,
          "candles:#{processed_candle.figi}",
          {:candle_update, processed_candle}
        )

      {:error, reason} ->
        Logger.error("Failed to process candle data: #{inspect(reason)}")
    end
  end
end
