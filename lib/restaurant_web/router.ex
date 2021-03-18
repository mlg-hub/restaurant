defmodule RestaurantWeb.Router do
  use RestaurantWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RestaurantWeb do
    pipe_through :api
    get "/stores", StoreController, :get_all_stores
    get "/stores_complete", StoreController, :get_complet_store
    get "/waiters", StaffController, :all_waiters
    get "/clients", StaffController, :all_clients
    get "/orders/:waiter_id", StaffController, :all_waiter_orders
    get "/orders/details/:order_id", OrderController, :get_products
    get "/payments/modes", PayController, :get_all_payments
    get "/payments/factures", PayController, :get_all_type_facture
    get "/staffs/req_transfer/:waiter_id", StaffController, :get_requested_transfer
    get "/staffs/get_split_request", StaffController, :get_split_request
    get "/staffs/get_produits_for_cmd/:cmd_id", StaffController, :get_produits_for_cmd
    post "/orders/create_payment", PayController, :create_payment
    post "/order", OrderController, :create_order
    post "/orders/void/:order_id", OrderController, :void_request
    post "/orders/split/:order_id", OrderController, :split_request
    post "/orders/confirm_transfer/:order_id", OrderController, :confirm_transfer_request
    post "/orders/send_transfer/:order_id/:transfer_to", OrderController, :send_transfer_request
    post "/staffs/open_shift/:user_id", StaffController, :open_shift
    post "/staffs/close_shift/:user_id", StaffController, :close_shift
    post "/login", StaffController, :login
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: RestaurantWeb.Telemetry
    end
  end
end
