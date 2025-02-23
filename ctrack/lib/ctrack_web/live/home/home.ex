defmodule CtrackWeb.Home do
  use CtrackWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    instruments = Application.get_env(:ctrack, :instruments)

    if connected?(socket) do
      Enum.each(instruments, fn %{figi: figi} ->
        Phoenix.PubSub.subscribe(Ctrack.PubSub, "candles:#{figi}")
      end)
    end

    socket =
      assign(socket,
        instruments: instruments,
        candles: %{},
        last_updates: %{}
      )

    {:ok, socket}
  end

  def handle_info({:candle_update, candle}, socket) do
    socket =
      socket
      |> update(:candles, fn candles -> Map.put(candles, candle.figi, candle) end)
      |> update(:last_updates, fn updates -> Map.put(updates, candle.figi, DateTime.utc_now()) end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h1 class="text-2xl font-bold mb-6">Биржевые данные</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for instrument <- @instruments do %>
          <.candle_card
            instrument={instrument}
            candle={Map.get(@candles, instrument.figi)}
            last_update={Map.get(@last_updates, instrument.figi)}
          />
        <% end %>
      </div>
    </div>
    """
  end

  def candle_card(assigns) do
    ~H"""
    <div class="rounded-lg p-6 shadow-lg transition-all bg-gray-100">
      <div class="flex justify-between items-start mb-4">
        <h2 class="text-lg font-semibold"><%= @instrument.name %></h2>
        <span class="text-xs text-gray-500"><%= @instrument.figi %></span>
      </div>

      <%= if @candle do %>
        <div class="grid grid-cols-2 gap-4 mb-4">
          <div class={["flex flex-col p-2 rounded", price_color(@candle.prices.open, @candle.prices.close)]}>
            <span class="text-gray-600 text-sm">Открытие</span>
            <span class="text-lg font-medium"><%= format_price(@candle.prices.open) %> ₽</span>
          </div>
          <div class={["flex flex-col p-2 rounded", price_color(@candle.prices.close, @candle.prices.open)]}>
            <span class="text-gray-600 text-sm">Текущая</span>
            <div class="flex items-center gap-2">
              <span class="text-lg font-medium"><%= format_price(@candle.prices.close) %> ₽</span>
              <span class={["text-sm", price_change_color(@candle.prices.close, @candle.prices.open)]}>
                <%= format_price_change(@candle.prices.close, @candle.prices.open) %>
              </span>
            </div>
          </div>
          <div class="flex flex-col p-2">
            <span class="text-gray-600 text-sm">Максимум</span>
            <span class="text-lg font-medium"><%= format_price(@candle.prices.high) %> ₽</span>
          </div>
          <div class="flex flex-col p-2">
            <span class="text-gray-600 text-sm">Минимум</span>
            <span class="text-lg font-medium"><%= format_price(@candle.prices.low) %> ₽</span>
          </div>
        </div>

        <div class="flex justify-between items-center text-sm">
          <div class="flex items-center gap-2">
            <span class="text-gray-600">Объём:</span>
            <span class="font-medium"><%= format_volume(@candle.volume) %></span>
          </div>
          <div class="text-gray-500">
            <%= parse_datetime(@candle.time) %> МСК
          </div>
        </div>

        <div class="mt-2 text-xs text-gray-500 text-right">
          Обновлено: <%= if @last_update, do: parse_datetime(@last_update), else: "Ожидание" %>
        </div>
      <% else %>
        <div class="h-32 flex items-center justify-center text-gray-500">
          Ожидание данных...
        </div>
      <% end %>
    </div>
    """
  end

  # Вспомогательные функции
  @doc """
  Преобразует строку времени в DateTime.
  """
  def parse_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift(hour: 3)
    |> Calendar.strftime("%H:%M:%S")
  end

  def parse_datetime(_), do: "Не дата :("

  defp format_price(price) do
    :erlang.float_to_binary(price, decimals: 2)
  end

  defp format_volume(volume) when volume >= 1_000_000 do
    :erlang.float_to_binary(volume / 1_000_000, decimals: 2) <> "M"
  end

  defp format_volume(volume) when volume >= 1_000 do
    :erlang.float_to_binary(volume / 1_000, decimals: 1) <> "K"
  end

  defp format_volume(volume), do: to_string(volume)

  defp price_color(current, previous) do
    cond do
      current > previous -> "bg-green-50"
      current < previous -> "bg-red-50"
      true -> "bg-gray-50"
    end
  end

  defp price_change_color(current, previous) do
    cond do
      current > previous -> "text-green-600"
      current < previous -> "text-red-600"
      true -> "text-gray-600"
    end
  end

  defp format_price_change(current, previous) do
    change_percent = (current - previous) / previous * 100
    sign = if change_percent > 0, do: "+", else: ""
    "#{sign}#{:erlang.float_to_binary(change_percent, decimals: 2)}%"
  end
end
