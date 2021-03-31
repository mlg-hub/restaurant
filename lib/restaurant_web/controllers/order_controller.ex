defmodule RestaurantWeb.OrderController do
  use RestaurantWeb, :controller
  alias Restaurant.Model.Api.Order

  def create_order(conn, params) do
    case Order.create_order(params) do
      {:ok, message: msg} -> json(conn, %{success: msg})
      _ -> json(conn, %{error: "order not created"})
    end
  end

  def update_order(conn, params) do
    case Order.update_order(params) do
      {:ok, message: msg} -> json(conn, %{success: msg})
      _ -> json(conn, %{error: "order not updated
      "})
    end
  end

  def void_request(conn, %{"order_id" => cmd_id}) do
    case Order.request_void_cmd(cmd_id) do
      {1, _} -> json(conn, %{success: "request to void with success"})
      _ -> json(conn, %{error: "could not request to void"})
    end
  end

  def cancel_void_request(conn, %{"order_id" => cmd_id}) do
    case Order.cancel_void_request(cmd_id) do
      {1, _} -> json(conn, %{success: "request to void was cancel"})
      _ -> json(conn, %{error: "could not cancel the void"})
    end
  end

  def split_request(conn, %{"order_id" => cmd_id}) do
    case Order.request_split_cmd(cmd_id) do
      {1, _} -> json(conn, %{success: "request to split with success"})
      _ -> json(conn, %{error: "could not request the split"})
    end
  end

  def send_transfer_request(conn, %{"transfer_to" => to_waiter_id, "order_id" => cmd_id}) do
    case Order.send_transfer_request(cmd_id, to_waiter_id) do
      {1, _} -> json(conn, %{success: "transfer request was successful"})
      _ -> json(conn, %{error: "transfer request was not successful"})
    end
  end

  def confirm_transfer_request(conn, %{"order_id" => cmd_id}) do
    case Order.confirm_transfer_request(cmd_id) do
      {1, _} -> json(conn, %{success: "transfer confirmed with success"})
      _ -> json(conn, %{error: "transfer not confirmed"})
    end
  end

  def cancel_transfer_request(conn, %{"order_id" => order_id}) do
    case Order.cancel_transfer_request(order_id) do
      {1, _} -> json(conn, %{success: "transfer canceled with success"})
      _ -> json(conn, %{error: "transfer could not be canceled"})
    end
  end

  # def create_paiement(conn, %{"paiement_info" => pay_info}) do
  #   case Order.create_payment(pay_info) do
  #     {1, _} -> json(conn, %{success: "payment was successfull"})
  #     _ -> json(conn, %{error: "paiement not successfull"})
  #   end
  # end

  def get_products(conn, %{"order_id" => order_id}) do
    list = Order.get_cmd_products(order_id)

    if is_list(list) do
      json(conn, %{success: "product list found", products: list})
    else
      json(conn, %{error: "could not retreive products"})
    end
  end
end
