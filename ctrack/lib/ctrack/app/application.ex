defmodule Ctrack.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CtrackWeb.Telemetry,
      Ctrack.Repo,
      {DNSCluster, query: Application.get_env(:ctrack, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ctrack.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Ctrack.Finch},
      # Start a worker by calling: Ctrack.Worker.start_link(arg)
      # {Ctrack.Worker, arg},
      # Start to serve requests, typically the last entry
      CtrackWeb.Endpoint,
      {Tbank.Websocket, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ctrack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CtrackWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
