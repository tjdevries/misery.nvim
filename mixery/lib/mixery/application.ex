defmodule Mixery.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MixeryWeb.Telemetry,
      Mixery.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:mixery, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:mixery, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mixery.PubSub},
      {Finch, name: Mixery.Finch},
      Mixery.Twitch.ApiHandler.child_spec(Application.fetch_env!(:mixery, :event_sub)),
      Mixery.Neovim.Connections,
      # Start a worker by calling: Mixery.Worker.start_link(arg)
      # {Mixery.Worker, arg},
      # Start to serve requests, typically the last entry
      MixeryWeb.Endpoint,
      {TwitchEventSub.WebSocket, Application.fetch_env!(:mixery, :event_sub)},
      {Mixery.OBS.Handler, uri: "ws://192.168.4.121:4455", state: %Mixery.OBS.State{}, opts: []},
      Mixery.Server
    ]

    Logger.add_handlers(:mixery)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mixery.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MixeryWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
