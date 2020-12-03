defmodule BoardGames.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BoardGamesWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BoardGames.PubSub},
      {BoardGames.GameSupervisor, []},
      {Registry, keys: :unique, name: :game_registry},
      # BoardGames.Presence,
      # Start the Endpoint (http/https)
      BoardGamesWeb.Endpoint,
      {BoardGames.LiveMonitor, %{}}
      # Start a worker by calling: BoardGames.Worker.start_link(arg)
      # {BoardGames.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BoardGames.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BoardGamesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
