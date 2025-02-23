defmodule CtrackWeb.Home do
  use CtrackWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Home
    """
  end
end
