defmodule RestaurantWeb.StaffController do
  use RestaurantWeb, :controller
  alias RestaurantWeb.Model.Api.Staff

  def all_waiters(conn, _params) do
    all_waiters = Staff.get_all_waiters()
    json(conn, all_waiters)
  end

  def all_clients(conn, _params) do
    all_clients = Staff.get_all_clients()
    json(conn, all_clients)
  end

  def all_waiter_orders(conn, %{"waiter_id" => waiter_id}) do
    all_cmds = Staff.get_waiter_orders(waiter_id)
    json(conn, all_cmds)
  end

  def get_requested_transfer(conn, %{"waiter_id" => waiter_id}) do
    all_transfer_req_cmd = Staff.get_requested_transfer(waiter_id)
    json(conn, all_transfer_req_cmd)
  end

  def get_split_request(conn, _params) do
    all_split_request = Staff.get_all_split_request()
    json(conn, all_split_request)
  end

  def get_produits_for_cmd(conn, %{"cmd_id" => cmd_id}) do
    prods = Staff.get_produits_for_cmd(cmd_id)
    json(conn, prods)
  end

  def login(conn, params) do
    case Staff.login(params) do
      %{} = user -> json(conn, user)
      _ -> json(conn, %{error: "Login failed"})
    end
  end

  def open_shift(conn, %{"user_id" => user_id}) do
    case Staff.open_shift(user_id) do
      {1, _} -> json(conn, %{success: "shift was created"})
      _ -> json(conn, %{error: "shift couldnt open"})
    end
  end

  def close_shift(conn, %{"user_id" => user_id}) do
    case Staff.close_shift(user_id) do
      {1, _} -> json(conn, %{success: "was close"})
      _ -> json(conn, %{error: "could not open shift"})
    end
  end
end
