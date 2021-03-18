# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :restaurant,
  ecto_repos: [Restaurant.Repo]

# Configures the endpoint
config :restaurant, RestaurantWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pu4BvqWG6yS1l8gIKU8Tv9mIrdq9sBY9Dt++lNIrvE6N/qX2ER+OUPD81boOkTAH",
  render_errors: [view: RestaurantWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Restaurant.PubSub,
  live_view: [signing_salt: "4YGAG4Yg"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
