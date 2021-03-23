defmodule RestaurantWeb.Presence do
  use Phoenix.Presence, otp_app: :restaurant, pubsub_server: Restaurant.PubSub
end
