defmodule PosCalculation do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    Process.send_after(self(), {:get_server_status, NaiveDateTime.local_now()}, 1000)
    # {:ok, bill_date} = NaiveDateTime.new(~D[2021-02-05], ~T[16:00:07.005])
    {:ok, nil, 60000}
  end

  def see_bill(current_date) do
    GenServer.call(__MODULE__, {:see_bill, current_date}, 180_000)
  end

  defp get_status do
    try do
      {:ok, %HTTPoison.Response{body: body}} =
        HTTPoison.get("http://insurance.ibi-africa.com/administrator/verify/getdate")

      %{"DATE_CONTENT" => date_time} = Jason.decode!(body)

      r =
        NaiveDateTime.new(
          Date.from_iso8601!(Enum.at(String.split(date_time), 0)),
          Time.from_iso8601!(Enum.at(String.split(date_time), 1))
        )

      r
    rescue
      _e ->
        NaiveDateTime.new(2021, 12, 11, 9, 30, 0)
    end
  end

  def get_server_status(current_time) do
    GenServer.call(__MODULE__, {:get_server_status, current_time})
  end

  def handle_info({:get_server_status, _current_date}, state) do
    if state == nil do
      case get_status() do
        {:error, _e} ->
          {:noreply, state}

        {:ok, time} ->
          # server_status = NaiveDateTime.compare(time, current_date)

          {:noreply, time}
      end
    else
      # server_status = NaiveDateTime.compare(state, current_date)
      {:noreply, state}
    end
  end

  def handle_call({:see_bill, current_date}, _from, state) do
    case get_status() do
      {:error, _} ->
        {:reply, nil, state}

      {:ok, time} ->
        server_status = NaiveDateTime.compare(time, current_date)
        {:reply, server_status, time}
    end
  end
end
