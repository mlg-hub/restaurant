defmodule RestaurantWeb.Model.Api.Staff do
  import Ecto.Query
  alias Restaurant.Repo
  alias Restaurant.Helpers.Const

  def login(%{"password" => pin_code}) do
    users = Const.users()

    user =
      Repo.one(
        from u in users,
          where: u.pin_code == ^pin_code and u.banned == 0,
          join: g in "aauth_user_to_group",
          on: g.user_id == u.id,
          join: ag in "aauth_groups",
          on: ag.id == g.group_id,
          select: %{
            full_name: u.full_name,
            user_id: u.id,
            group_id: g.group_id,
            group_name: ag.name
          }
      )

    user
  end

  def get_all_waiters do
    #! TODO: must look in to the group of the user
    users_tab = Const.users()

    users =
      from(u in users_tab,
        where: u.banned == 0,
        order_by: [asc: u.full_name],
        select: %{user_id: u.id, full_name: u.full_name},
        limit: 10
      )
      |> Repo.all()

    users
  end

  def get_one_client(client_id) do
    clients_tab = Const.clients_tab()
    clients_file = Const.client_file_tab()

    client =
      from(c in clients_tab,
        join: f in ^clients_file,
        on: f.client_id == c.id_client,
        where: c.delete_status_client == 0 and c.id_client == ^client_id,
        select: %{
          client_name: c.nom_client,
          client_id: c.id_client,
          client_prenom: c.prenom,
          type_client: c.type_client_id,
          phone_number: c.tel_clients,
          client_file_id: f.client_file_id,
          client_file_code: f.client_file_code,
          discount_food: f.discount_food,
          discount_boisson: f.discount_boisson
        }
      )
      |> Repo.one!()

    client
  end

  def get_discount_percent(type, client) do
    if type == 0 do
      client.discount_boisson
    else
      client.discount_food
    end
  end

  def get_all_clients do
    clients_tab = Const.clients_tab()
    clients_file = Const.client_file_tab()

    clients =
      from(c in clients_tab,
        join: f in ^clients_file,
        on: f.client_id == c.id_client,
        where: c.delete_status_client == 0,
        select: %{
          client_name: c.nom_client,
          client_id: c.id_client,
          client_prenom: c.prenom,
          type_client: c.type_client_id,
          phone_number: c.tel_clients,
          client_file_id: f.client_file_id,
          client_file_code: f.client_file_code,
          discount_food: f.discount_food,
          discount_boisson: f.discount_boisson
        }
      )
      |> Repo.all()

    clients
  end

  def get_cmd_with_status(cashier_id, status \\ "pending") do
    map_status = %{"pending" => 0, "paid" => 2, "avance" => 1, "unpaid" => 10, "compl" => 11}
    value_status = Map.get(map_status, status)
    cmd_tab = Const.commandes()
    cmd_prod_tab = Const.commandes_produits()
    clients_tab = Const.clients_tab()
    articles = Const.articles(1)

    current_shift =
      Repo.one!(
        from(s in "cashier_shifts",
          where: s.created_by_shift == ^cashier_id and s.shift_status == 0,
          select: %{
            id: s.id_shift
          }
        )
      )

    cmd_with_details =
      from(c in cmd_tab,
        join: cl in ^clients_tab,
        on: cl.id_client == c.client_id_commande,
        join: cp in ^cmd_prod_tab,
        on: cp.restaurant_ibi_commandes_id == c.id_restaurant_ibi_commandes,
        join: a in ^articles,
        on: cp.ref_product_codebar == a.codebar_article,
        order_by: [desc: c.date_creation_restaurant_ibi_commandes],
        where: c.commande_status == ^value_status and c.id_cashier_shift == ^current_shift.id,
        select: %{
          cmd_id: c.id_restaurant_ibi_commandes,
          code: c.code,
          created_at: c.date_creation_restaurant_ibi_commandes,
          created_by: c.created_by_restaurant_ibi_commandes,
          tva: c.tva,
          client_id: cl.id_client,
          client_name: cl.nom_client,
          client_prenom: cl.prenom,
          prod_name: cp.name,
          table_id: c.table_id,
          prod_quantity: cp.quantite,
          article_id: a.id_article,
          article_codebar: a.codebar_article,
          prod_id: cp.id_restaurant_ibi_commandes_produits,
          store_id: cp.store_id_restaurant_ibi_commandes_produits,
          prod_price: cp.prix,
          discount_percent: cp.discount_percent,
          article_type: a.type_article,
          article_nature: a.nature_article
        }
      )
      |> Repo.all()

    cmd_with_details
  end

  def get_waiter_split_orders() do
    cmd_tab = Const.commandes()
    cmd_prod_tab = Const.commandes_produits()
    clients_tab = Const.clients_tab()
    articles = Const.articles(1)

    cmd_with_details =
      from(c in cmd_tab,
        join: cl in ^clients_tab,
        on: cl.id_client == c.client_id_commande,
        join: cp in ^cmd_prod_tab,
        on: cp.restaurant_ibi_commandes_id == c.id_restaurant_ibi_commandes,
        join: u in "aauth_users",
        on: u.id == c.created_by_restaurant_ibi_commandes,
        left_join: a in ^articles,
        on: cp.ref_product_codebar == a.codebar_article,
        order_by: [desc: c.date_creation_restaurant_ibi_commandes],
        where: c.commande_split_request == 1 and c.commande_status == 0,
        select: %{
          cmd_id: c.id_restaurant_ibi_commandes,
          code: c.code,
          created_at: c.date_creation_restaurant_ibi_commandes,
          created_by: c.created_by_restaurant_ibi_commandes,
          tva: c.tva,
          table_id: c.table_id,
          client_id: cl.id_client,
          client_name: cl.nom_client,
          responsable: u.full_name,
          client_prenom: cl.prenom,
          prod_name: cp.name,
          prod_quantity: cp.quantite,
          prod_price: cp.prix,
          article_id: a.id_article,
          article_codebar: a.codebar_article,
          prod_id: cp.id_restaurant_ibi_commandes_produits,
          store_id: cp.store_id_restaurant_ibi_commandes_produits,
          discount_percent: cp.discount_percent,
          article_type: a.type_article,
          article_nature: a.nature_article
        }
      )
      |> Repo.all()

    cmd_with_details
  end

  def get_waiter_orders(waiter_id) do
    cmd_tab = Const.commandes()
    cmd_prod_tab = Const.commandes_produits()
    clients_tab = Const.clients_tab()
    articles = Const.articles(1)

    cmd_with_details =
      from(c in cmd_tab,
        join: cl in ^clients_tab,
        on: cl.id_client == c.client_id_commande,
        join: cp in ^cmd_prod_tab,
        on: cp.restaurant_ibi_commandes_id == c.id_restaurant_ibi_commandes,
        left_join: a in ^articles,
        on: cp.ref_product_codebar == a.codebar_article,
        join: u in "aauth_users",
        on: u.id == c.created_by_restaurant_ibi_commandes,
        order_by: [desc: c.date_creation_restaurant_ibi_commandes],
        where:
          ((c.created_by_restaurant_ibi_commandes == ^waiter_id and c.transfer_status == 0) or
             (c.transfer_to == ^waiter_id and c.transfer_status == 1)) and c.commande_status == 0 and
            c.deleted_status_restaurant_ibi_commandes,
        select: %{
          cmd_id: c.id_restaurant_ibi_commandes,
          code: c.code,
          created_at: c.date_creation_restaurant_ibi_commandes,
          tva: c.tva,
          responsable: u.full_name,
          client_id: cl.id_client,
          client_name: cl.nom_client,
          client_prenom: cl.prenom,
          prod_name: cp.name,
          table_id: c.table_id,
          prod_quantity: cp.quantite,
          prod_price: cp.prix,
          discount_percent: cp.discount_percent,
          article_type: a.type_article,
          article_nature: a.nature_article,
          article_codebar: a.codebar_article
        }
      )
      |> Repo.all()

    cmd_with_details
  end

  def get_requested_transfer(waiter_id) do
    cmds = Const.commandes()

    from(c in cmds,
      left_join: u in "aauth_users",
      on: u.id == c.created_by_restaurant_ibi_commandes,
      where:
        c.transfer_to == ^waiter_id and
          c.transfer_status == 0 and
          c.commande_status == 0,
      select: %{
        cmd_id: c.id_restaurant_ibi_commandes,
        code: c.code,
        from: u.full_name,
        cmd_date: c.date_creation_restaurant_ibi_commandes
      }
    )
    |> Repo.all()
  end

  def get_all_split_request() do
    cmds = Const.commandes()

    from(
      c in cmds,
      join: u in "aauth_users",
      on: u.id == c.created_by_restaurant_ibi_commandes,
      where: c.commande_split_request == 1 and c.commande_status == 0,
      select: %{
        from: u.full_name,
        code: c.code,
        created_by: c.created_by_restaurant_ibi_commandes,
        cmd_id: c.id_restaurant_ibi_commandes,
        cmd_date: c.date_creation_restaurant_ibi_commandes
      }
    )
    |> Repo.all()
  end

  def get_produits_for_cmd(cmd_id) do
    cmds = Const.commandes_produits()

    from(cp in cmds,
      where: cp.restaurant_ibi_commandes_id == ^cmd_id,
      select: %{
        id: cp.id_restaurant_ibi_commandes_produits,
        code_bar: cp.ref_product_codebar,
        quantity: cp.quantite,
        prix: cp.prix,
        name: cp.name,
        date_creation: cp.date_creation_restaurant_ibi_commandes_produits
      }
    )
    |> Repo.all()
  end

  def check_shift_open() do
    from(c in "cashier_shifts",
      where: c.shift_status == 0,
      select: %{shift_start: c.shift_start}
    )
    |> Repo.all()
  end

  def check_shift_open(user_id) do
    from(c in "cashier_shifts",
      where: c.created_by_shift == ^user_id and c.shift_status == 0,
      select: %{shift_start: c.shift_start}
    )
    |> Repo.one()
  end

  def open_shift(user_id) do
    shift_tab = "cashier_shifts"
    now = NaiveDateTime.to_iso8601(NaiveDateTime.local_now())
    shift_data = %{shift_start: now, created_by_shift: user_id}
    Repo.insert_all(shift_tab, [shift_data])
  end

  def close_shift(user_id) do
    shift_tab = "cashier_shifts"
    now = NaiveDateTime.to_iso8601(NaiveDateTime.local_now())

    # TODO: get cashier summary
    summary_info = get_cashier_summary(user_id)

    from(
      s in shift_tab,
      update: [set: [shift_end: ^now, updated_at_shift: ^now, shift_status: 1]],
      where: s.created_by_shift == ^user_id and s.shift_status == 0
    )
    |> Repo.update_all([])

    summary_info
  end

  def get_cashier_summary(cashier_id) do
    # get the current active shift

    try do
      end_time = NaiveDateTime.local_now() |> NaiveDateTime.to_iso8601()

      active_shift =
        Repo.one!(
          from(s in "cashier_shifts",
            where: s.created_by_shift == ^cashier_id and s.shift_status == 0,
            select: %{
              shift_id: s.id_shift,
              start_time: s.shift_start,
              end_time: ^end_time
            }
          )
        )

      # starting an agent process
      {:ok, pid} =
        Agent.start_link(fn ->
          %{}
        end)

      Enum.each(["paid", "unpaid", "complementary"], fn el ->
        case el do
          "paid" ->
            data_received =
              from(c in Const.commandes(),
                where:
                  (c.commande_status == 1 or c.commande_status == 2) and
                    c.id_cashier_shift == ^active_shift.shift_id,
                join: p in "restaurant_paiements",
                on:
                  p.commande_id == c.id_restaurant_ibi_commandes and
                    p.shift_id == ^active_shift.shift_id,
                left_join: cp in "restaurant_ibi_commandes_produits",
                on: cp.restaurant_ibi_commandes_id == c.id_restaurant_ibi_commandes,
                left_join: s in "restaurant_ibi_stores",
                on: s.id_store == cp.store_id_restaurant_ibi_commandes_produits,
                select: %{
                  montant: p.montant_paiement,
                  pay_id: p.id_paiement,
                  store_name: s.name_store,
                  total_prod:
                    cp.quantite * cp.prix - cp.quantite * cp.prix * cp.discount_percent / 100,
                  prod_id: cp.id_restaurant_ibi_commandes_produits
                }
              )
              |> Repo.all()
              |> treat_data(:received, pid, "paid")

            Agent.cast(pid, fn s ->
              Map.put_new(s, :paid, %{
                stores: data_received.store_data,
                cash_in_hand: data_received.total,
                type: "paid"
              })
            end)

          "unpaid" ->
            unpaid_data =
              from(c in Const.commandes(),
                where:
                  c.commande_status == 10 and
                    c.id_cashier_shift == ^active_shift.shift_id,
                left_join: p in "restaurant_paiements",
                on:
                  p.commande_id == c.id_restaurant_ibi_commandes and
                    p.shift_id == ^active_shift.shift_id,
                left_join: cp in "restaurant_ibi_commandes_produits",
                on: cp.restaurant_ibi_commandes_id == c.id_restaurant_ibi_commandes,
                left_join: s in "restaurant_ibi_stores",
                on: s.id_store == cp.store_id_restaurant_ibi_commandes_produits,
                select: %{
                  montant: p.montant_paiement,
                  pay_id: p.id_paiement,
                  store_name: s.name_store,
                  total_prod:
                    cp.quantite * cp.prix - cp.quantite * cp.prix * cp.discount_percent / 100,
                  prod_id: cp.id_restaurant_ibi_commandes_produits
                }
              )
              |> Repo.all()
              |> treat_data(:received, pid, "unpaid")

            Agent.cast(pid, fn s ->
              Map.put_new(s, :unpaid, %{
                stores: unpaid_data.store_data,
                total: Enum.sum(Map.values(unpaid_data.store_data)),
                type: "unpaid"
              })
            end)

          "complementary" ->
            compl_data =
              from(c in Const.commandes(),
                where:
                  c.commande_status == 11 and
                    c.id_cashier_shift == ^active_shift.shift_id,
                left_join: p in "restaurant_paiements",
                on:
                  p.commande_id == c.id_restaurant_ibi_commandes and
                    p.shift_id == ^active_shift.shift_id,
                left_join: cp in "restaurant_ibi_commandes_produits",
                on: cp.restaurant_ibi_commandes_id == c.id_restaurant_ibi_commandes,
                left_join: s in "restaurant_ibi_stores",
                on: s.id_store == cp.store_id_restaurant_ibi_commandes_produits,
                select: %{
                  montant: p.montant_paiement,
                  pay_id: p.id_paiement,
                  store_name: s.name_store,
                  total_prod:
                    cp.quantite * cp.prix - cp.quantite * cp.prix * cp.discount_percent / 100,
                  prod_id: cp.id_restaurant_ibi_commandes_produits
                }
              )
              |> Repo.all()
              |> treat_data(:received, pid, "complementary")

            Agent.cast(pid, fn s ->
              Map.put_new(s, :complementary, %{
                stores: compl_data.store_data,
                total: Enum.sum(Map.values(compl_data.store_data)),
                type: "complementary"
              })
            end)
        end
      end)

      result = Agent.get(pid, fn s -> s end)
      Agent.stop(pid)

      result
      |> Map.put_new(
        :start_time,
        String.split(NaiveDateTime.to_iso8601(active_shift.start_time), "T") |> Enum.join(" ")
      )
      |> Map.put_new(:end_time, String.split(active_shift.end_time, "T") |> Enum.join(" "))
    catch
      value ->
        IO.puts("Caught #{inspect(value)}")
    end
  end

  defp treat_data(data, :received, _pid, type) do
    IO.inspect(data)

    map_structure = %{
      pay_ids: [],
      store_data: %{},
      total: 0,
      type: type
    }

    transform_data(data, map_structure)
  end

  defp transform_data([head | tail], map) do
    IO.puts("now the map is #{inspect(map)}")

    if !Enum.member?(map.pay_ids, head.pay_id) do
      map = Map.put(map, :pay_ids, map.pay_ids ++ [head.pay_id])

      montant =
        if is_nil(head.montant) do
          0.0
        else
          head.montant
        end

      map1 =
        Map.put(map, :total, map.total + Float.floor(montant))
        |> update_store_data(head)

      map = Map.merge(map, map1)
      transform_data(tail, map)
    else
      map1 =
        map
        |> update_store_data(head)

      map = Map.merge(map, map1)
      transform_data(tail, map)
    end
  end

  defp transform_data([], map) do
    map
  end

  defp update_store_data(map, head) do
    if Map.has_key?(map.store_data, head.store_name) do
      map1 =
        Map.put(
          map.store_data,
          head.store_name,
          map.store_data[head.store_name] + head.total_prod
        )

      map = %{map | store_data: map1}
      map
    else
      map1 = Map.put_new(map.store_data, head.store_name, head.total_prod)
      map = %{map | store_data: map1}
      map
    end
  end
end
