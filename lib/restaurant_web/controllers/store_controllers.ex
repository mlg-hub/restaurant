defmodule RestaurantWeb.StoreController do
  use RestaurantWeb, :controller
  alias Restaurant.Model.Api.Store

  def get_all_stores(conn, _params) do
    all_stores = Store.get_all_stores()
    json(conn, all_stores)
  end

  def get_complet_store(conn, _params) do
    store_data = Store.get_all_stores_complete()
    json(conn, store_data)
  end
end
