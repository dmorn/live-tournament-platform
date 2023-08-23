defmodule LTP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LTPWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LTP.PubSub},
      # Start Finch
      {Finch, name: LTP.Finch},
      # Start the Endpoint (http/https)
      LTPWeb.Endpoint,
      LTP.App
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LTP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LTPWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
