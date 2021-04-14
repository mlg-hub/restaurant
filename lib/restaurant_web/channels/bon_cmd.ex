defmodule RestaurantWeb.Channels.BonCommandes do
  use RestaurantWeb, :channel
  alias Restaurant.System.{KitchenPrint, RestaurantPrint, MiniBarPrint, MainBarPrint}

  def join("bon_cmd:" <> dpt_name, _params, socket) do
    send(self(), {:fetch_pending, dpt_name, false})
    {:ok, %{joined: true}, socket}
  end

  def handle_in("fetch_pending", %{"dpt" => dpt}, socket) do
    Process.send_after(self(), {:fetch_pending, dpt, true}, 2000)
    {:reply, :ok, socket}
  end

  def handle_in("used_fetch", %{"dpt" => dpt, "bons" => bons}, socket) do
    case(dpt) do
      "kitchen" ->
        Enum.each(bons, fn bon ->
          code = Enum.at(bon, 0)["code_stamp"]

          KitchenPrint.set_bon_used(code)
        end)

      "mainbar" ->
        Enum.each(bons, fn bon ->
          code = Enum.at(bon, 0)["code_stamp"]
          MainBarPrint.set_bon_used(code)
        end)

      "restaurant" ->
        Enum.each(bons, fn bon ->
          code = Enum.at(bon, 0)["code_stamp"]
          RestaurantPrint.set_bon_used(code)
        end)

      "minibar" ->
        Enum.each(bons, fn bon ->
          code = Enum.at(bon, 0)["code_stamp"]
          MiniBarPrint.set_bon_used(code)
        end)
    end

    {:reply, :ok, socket}
  end

  def handle_in("used", %{"dpt" => dpt, "bon" => bon}, socket) do
    IO.puts("it was used hahahahah")

    case(dpt) do
      "kitchen" ->
        KitchenPrint.set_bon_used(bon)

      "mainbar" ->
        MainBarPrint.set_bon_used(bon)

      "restaurant" ->
        RestaurantPrint.set_bon_used(bon)

      "minibar" ->
        MiniBarPrint.set_bon_used(bon)
    end

    {:reply, :ok, socket}
  end

  def handle_info({:fetch_pending, dpt_name, on_push_btn}, socket) do
    case dpt_name do
      "kitchen" ->
        {:ok, pending_bons} = KitchenPrint.get_all_bons_status("pending")

        bons_refined = treat_bons(pending_bons)

        if on_push_btn do
          if(Enum.count(bons_refined) > 0) do
            RestaurantWeb.Endpoint.broadcast!("bon_cmd:kitchen", "printfetch", %{
              bons: bons_refined,
              print: 1
            })
          end
        else
          RestaurantWeb.Endpoint.broadcast!("bon_cmd:kitchen", "printfetch", %{
            bons: Enum.count(bons_refined),
            print: 0
          })
        end

      "mainbar" ->
        {:ok, pending_bons} = MainBarPrint.get_all_bons_status("pending")

        bons_refined = treat_bons(pending_bons)

        if on_push_btn do
          if(Enum.count(bons_refined) > 0) do
            RestaurantWeb.Endpoint.broadcast!("bon_cmd:mainbar", "printfetch", %{
              bons: bons_refined,
              print: 1
            })
          end
        else
          RestaurantWeb.Endpoint.broadcast!("bon_cmd:mainbar", "printfetch", %{
            bons: Enum.count(bons_refined),
            print: 0
          })
        end

      "restaurant" ->
        {:ok, pending_bons} = RestaurantPrint.get_all_bons_status("pending")
        bons_refined = treat_bons(pending_bons)

        if on_push_btn do
          if(Enum.count(bons_refined) > 0) do
            RestaurantWeb.Endpoint.broadcast!("bon_cmd:restaurant", "printfetch", %{
              bons: bons_refined,
              print: 1
            })
          end
        else
          RestaurantWeb.Endpoint.broadcast!("bon_cmd:restaurant", "printfetch", %{
            bons: Enum.count(bons_refined),
            print: 0
          })
        end

      "minibar" ->
        {:ok, pending_bons} = RestaurantPrint.get_all_bons_status("pending")
        bons_refined = treat_bons(pending_bons)

        if on_push_btn do
          if(Enum.count(bons_refined) > 0) do
            RestaurantWeb.Endpoint.broadcast!("bon_cmd:minibar", "printfetch", %{
              bons: bons_refined,
              print: 1
            })
          end
        else
          RestaurantWeb.Endpoint.broadcast!("bon_cmd:minibar", "printfetch", %{
            bons: Enum.count(bons_refined),
            print: 0
          })
        end
    end

    {:noreply, socket}
  end

  defp treat_bons(pending_bons) do
    Enum.map(pending_bons, fn {stamp, _status, data} ->
      new_bon =
        Enum.map(data, fn bon ->
          order_time =
            String.split(stamp, bon.ref_command_code)
            |> Enum.join("")
            |> String.split(".")
            |> Enum.at(0)

          Map.put_new(bon, :order_time, order_time)
        end)

      new_bon
    end)
  end
end
