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

    instruments = [
      %{"figi" => "BBG001J4BCN4"},
      %{"figi" => "BBG0013HG026"},
      %{"figi" => "BBG004730RP0", "instrumentId" => "c7c26356-7352-4c37-8316-b1d93b18e16e"}
    ]

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
        Logger.debug("Received message: #{inspect(msg)}")
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
              |> Map.put("interval", "SUBSCRIPTION_INTERVAL_ONE_MINUTE")
            end
          ),
        "waitingClose" => false
      }
    }
  end

  defp handle_candle_data(candle, _) do
  end
end
