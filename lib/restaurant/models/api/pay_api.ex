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
    IO.inspect(payment_data)

    %{
      "cmd_id" => cmd_id,
      "facture" => type_facture,
      "payments" => payments,
      "client_id" => user_id
    } = payment_data

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
          update: [set: [commande_status: ^status]]
        )
        |> Repo.update_all([])

        {num, _} =
          Repo.insert_all("restaurant_paiements", [
            %{
              commande_id: cmd_id,
              montant_paiement: 0,
              type_facture: type_facture,
              client_id_paiement: payment_data["client_id"],
              created_by_paiement: user_id
            }
          ])

        if num == 1 do
          %{success: "payment done with success"}
        else
          %{error: "payment not good"}
        end

      Enum.member?([2, 3], String.to_integer(type_facture)) ->
        if String.to_integer(type_facture) == 2 do
          from(c in cmd_tab,
            where: c.id_restaurant_ibi_commandes == ^cmd_id,
            update: [set: [commande_status: 1]]
          )
          |> Repo.update_all([])
        else
          from(c in cmd_tab,
            where: c.id_restaurant_ibi_commandes == ^cmd_id,
            update: [set: [commande_status: 2]]
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
                client_id_paiement: payment_data["client_id"],
                created_by_paiement: user_id
              }
            end)

          {num, _} = Repo.insert_all("restaurant_paiements", pay)

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
                created_by_paiement: user_id
              }
            ])

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
end
