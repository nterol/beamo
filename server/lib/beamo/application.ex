defmodule Beamo.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BeamoWeb.Telemetry,
      Beamo.Repo,
      {DNSCluster, query: Application.get_env(:beamo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Beamo.PubSub},
      {Oban, Application.fetch_env!(:beamo, Oban)},
      {Beamo.RateLimit, clean_period: :timer.minutes(10)},
      # Start to serve requests, typically the last entry
      BeamoWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Beamo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BeamoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
