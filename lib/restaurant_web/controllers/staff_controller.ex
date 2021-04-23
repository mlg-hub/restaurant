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

  def all_waiter_split_orders(conn, _params) do
    all_cmds = Staff.get_waiter_split_orders()
    json(conn, all_cmds)
  end

  def get_shift_status(conn, %{"cashier_id" => cashier_id}) do
    my_shift = Staff.get_shift_status(cashier_id)
    json(conn, my_shift)
  end

  def get_requested_transfer(conn, %{"waiter_id" => waiter_id}) do
    all_transfer_req_cmd = Staff.get_requested_transfer(waiter_id)
    json(conn, all_transfer_req_cmd)
  end

  @spec get_split_request(Plug.Conn.t(), any) :: Plug.Conn.t()
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

  def check_shift(conn, %{"all" => _all}) do
    case Staff.check_shift_open() do
      resp ->
        if Enum.count(resp) > 0 do
          json(conn, %{success: "has open", data: Enum.at(resp, 0)})
        else
          json(conn, %{empty: "not open"})
        end
    end
  end

  def check_shift(conn, %{"cashier_id" => cashier_id}) do
    case(Staff.check_shift_open(cashier_id)) do
      %{} = resp -> json(conn, %{success: "has open", data: resp})
      _ -> json(conn, %{empty: "not open"})
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
      %{} = resp -> json(conn, %{success: "shift was close", data: resp})
      _ -> json(conn, %{error: "could not open shift"})
    end
  end
end
