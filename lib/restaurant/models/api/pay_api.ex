defmodule Restaurant.Model.Api.Pay do
  import Ecto.Query
  alias Restaurant.Repo
  alias Restaurant.Helpers.Const

  def get_all_type_facture do
    facture = Const.type_facture()

    Repo.all(
      from(f in facture,
        where: f.is_pos == 0,
        select: %{type_id: f.id_type_facture, type_name: f.designation_type_facture}
      )
    )
  end

  def get_all_mode do
    mode = Const.mode_payments()

    Repo.all(
      from(m in mode,
        select: %{mode_id: m.id_mode_paiement, mode_name: m.designation_paiement_mode}
      )
    )
  end

  def create_payment(payment_data) do
    cmd_tab = Const.commandes()

    # payment_data = Map.update!()
    # IO.inspect(payment_data)

    %{
      "cmd_id" => cmd_id,
      "facture" => type_facture,
      "payments" => payments,
      "client_id" => client_id,
      "user_id" => user_id
    } = payment_data

    # add shift to payment ASAP
    current_shift =
      Repo.one!(
        from(a in "cashier_shifts",
          where: a.created_by_shift == ^user_id and a.shift_status == 0,
          select: %{
            id_shift: a.id_shift
          }
        )
      )

    cmd_info =
      Repo.one!(
        from(c in "restaurant_ibi_commandes",
          where: c.id_restaurant_ibi_commandes == ^cmd_id,
          select: %{creation: c.date_creation_restaurant_ibi_commandes}
        )
      )

    cond do
      Enum.member?([1, 4], String.to_integer(type_facture)) ->
        status =
          if String.to_integer(type_facture) == 1 do
            10
          else
            11
          end

        from(c in cmd_tab,
          where: c.id_restaurant_ibi_commandes == ^cmd_id,
          update: [set: [commande_status: ^status, id_cashier_shift: ^current_shift.id_shift]]
        )
        |> Repo.update_all([])

        {num, _} =
          Repo.insert_all("restaurant_paiements", [
            %{
              commande_id: cmd_id,
              montant_paiement: 0,
              type_facture: type_facture,
              client_id_paiement: client_id,
              created_by_paiement: user_id,
              shift_id: current_shift.id_shift,
              date_creation_commande: cmd_info.creation
            }
          ])

        spawn(fn ->
          update_stock_flow_with_shift(cmd_id, current_shift.id_shift)
        end)

        if num == 1 do
          %{success: "payment done with success"}
        else
          %{error: "payment not good"}
        end

      Enum.member?([2, 3], String.to_integer(type_facture)) ->
        if String.to_integer(type_facture) == 2 do
          from(c in cmd_tab,
            where: c.id_restaurant_ibi_commandes == ^cmd_id,
            update: [set: [commande_status: 1, id_cashier_shift: ^current_shift.id_shift]]
          )
          |> Repo.update_all([])
        else
          from(c in cmd_tab,
            where: c.id_restaurant_ibi_commandes == ^cmd_id,
            update: [set: [commande_status: 2, id_cashier_shift: ^current_shift.id_shift]]
          )
          |> Repo.update_all([])
        end

        if(String.to_integer(payment_data["mode"]) == 0) do
          payments = Jason.decode!(payments)

          pay =
            Enum.map(payments, fn x ->
              %{
                commande_id: cmd_id,
                montant_paiement: x["amount"],
                mode_paiement: x["mode"],
                type_facture: type_facture,
                client_id_paiement: client_id,
                created_by_paiement: user_id,
                shift_id: current_shift.id_shift,
                date_creation_commande: cmd_info.creation
              }
            end)

          {num, _} = Repo.insert_all("restaurant_paiements", pay)

          spawn(fn ->
            update_stock_flow_with_shift(cmd_id, current_shift.id_shift)
          end)

          if num == 2 do
            %{success: "payment done with success"}
          else
            %{error: "mix payment not done correctly"}
          end
        else
          {num, _} =
            Repo.insert_all("restaurant_paiements", [
              %{
                commande_id: cmd_id,
                montant_paiement: payment_data["amount"],
                mode_paiement: payment_data["mode"],
                type_facture: type_facture,
                client_id_paiement: payment_data["client_id"],
                created_by_paiement: user_id,
                shift_id: current_shift.id_shift,
                date_creation_commande: cmd_info.creation
              }
            ])

          spawn(fn ->
            update_stock_flow_with_shift(cmd_id, current_shift.id_shift)
          end)

          if num == 1 do
            %{success: "payment done with success"}
          else
            %{error: "mix payment not done correctly"}
          end
        end

      true ->
        %{error: "mix payment not done correctly"}
    end
  end

  def update_stock_flow_with_shift(cmd_id, shift_id) do
    cmd =
      from(c in "restaurant_ibi_commandes",
        where: c.id_restaurant_ibi_commandes == ^cmd_id,
        select: %{code: c.code}
      )
      |> Repo.one!()

    stores =
      from(s in "restaurant_ibi_stores",
        where: s.is_pos == 1 and s.status_store == "opened",
        select: %{
          store_id: s.id_store
        }
      )
      |> Repo.all()

    Enum.each(stores, fn st ->
      stock_tab =
        "restaurant_store_" <> Integer.to_string(st.store_id) <> "_ibi_articles_stock_flow"

      spawn(fn ->
        from(c in stock_tab,
          where: c.ref_command_code_sf == ^cmd.code,
          update: [set: [shift_id_s: ^shift_id]]
        )
        |> Repo.update_all([])
      end)
    end)
  end
end
