defmodule Restaurant.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Restaurant.Repo,
      # Start the Telemetry supervisor
      RestaurantWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Restaurant.PubSub},
      PosCalculation,
      # Start the Endpoint (http/https)
      RestaurantWeb.Endpoint,
      RestaurantWeb.Presence,
      Restaurant.System.KitchenPrint,
      Restaurant.System.MainBarPrint,
      Restaurant.System.RestoBarPrint
      # Start a worker by calling: Restaurant.Worker.start_link(arg)
      # {Restaurant.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Restaurant.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RestaurantWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
