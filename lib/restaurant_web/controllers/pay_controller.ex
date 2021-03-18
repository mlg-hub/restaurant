defmodule RestaurantWeb.PayController do
  use RestaurantWeb, :controller
  alias Restaurant.Model.Api.Pay

  def get_all_payments(conn, _params) do
    json(conn, Pay.get_all_mode())
  end

  def get_all_type_facture(conn, _params) do
    json(conn, Pay.get_all_type_facture())
  end

  def create_payment(conn, params) do
    IO.inspect(params)
    response = Pay.create_payment(params)
    json(conn, response)
  end
end
