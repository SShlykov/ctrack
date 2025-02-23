defmodule CtrackWeb.PageLive do
  use CtrackWeb, :live_view

  def mount(_, _, socket) do
    # The home page is often custom made,
    # so skip the default app layout.
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div style="height: calc(100vh - 2.5rem)" class="flex items-center justify-center from-indigo-600/50 to-emerald-800/50 bg-gradient-to-tr">
      <div className="text-center">
        <p class="text-center font-serif text-xl leading-6 drop-shadow-md text-white italic sm:text-2xl sm:leading-8">
          "Путь в тысячу миль начинается с первого шага"
        </p>
        <div class="text-gray-100 text-xl font-mono tracking-wider text-right drop-shadow-md">
          — Лао-цзы
        </div>
      </div>
    </div>
    """
  end
end
