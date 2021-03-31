defmodule Restaurant.Model.Api.Order do
  import Ecto.Query
  alias Restaurant.Repo
  alias Restaurant.Helpers.Const
  alias Restaurant.Models.OrderData
  alias RestaurantWeb.Model.Api.Staff
  alias Restaurant.System.KitchenPrint
  alias Restaurant.System.MainBarPrint
  alias Restaurant.System.RestoBarPrint

  def create_order(
        %{
          "client_id_commande" => client_id_commande,
          "products" => products
        } \\ %OrderData{}
      ) do
    user_id = 1

    responsable =
      Repo.one!(
        from(u in "aauth_users",
          where: u.id == ^user_id,
          select: %{full_name: u.full_name, id: u.id}
        )
      )

    current_shift_id = 1

    client = Staff.get_one_client(client_id_commande)
    attrs = %{products: Jason.decode!(products)}

    attrs =
      Map.update(attrs, :products, [], &build_products/1)
      |> Map.put(:cashier_shifts_id, current_shift_id)

    cmd_code = make_ordercode()

    Repo.insert_all(
      "restaurant_ibi_commandes",
      [
        %{
          code: cmd_code,
          client_id_commande: client_id_commande,
          id_cashier_shift: current_shift_id,
          tva: 18,
          created_by_restaurant_ibi_commandes: user_id
        }
      ]
    )

    last_cmd =
      Repo.one(
        from c in "restaurant_ibi_commandes",
          where: c.created_by_restaurant_ibi_commandes == ^user_id,
          order_by: [desc: c.id_restaurant_ibi_commandes],
          select: %{id: c.id_restaurant_ibi_commandes},
          limit: 1
      )

    cmd_id =
      if last_cmd == nil do
        1
      else
        last_cmd.id
      end

    {:ok, kitchen_pid} = Agent.start_link(fn -> [] end)
    {:ok, mainbar_pid} = Agent.start_link(fn -> [] end)
    {:ok, restobar_pid} = Agent.start_link(fn -> [] end)
    # prevent a column to be negative
    # ALTER TABLE Branch ADD CONSTRAINT chkassets CHECK (assets > 0);
    [to_save_details, to_save_flow] =
      transfrom_products(
        [kitchen_pid, mainbar_pid, restobar_pid, attrs.products],
        client,
        cmd_id,
        cmd_code,
        responsable
      )

    insert_cmd_details(to_save_details)
    send_bon_cmd([kitchen_pid, mainbar_pid, restobar_pid])
    insert_stock_flow(to_save_flow)
  end

  def update_order(%{
        "cmd_id" => cmd_id,
        "cmd_code" => cmd_code,
        "is_acc" => is_acc,
        "client_id_commande" => client_id_commande,
        "products" => products
      }) do
    #! TODO: user is static need to change
    user_id = 1

    is_acc =
      if is_acc == "true" do
        true
      else
        false
      end

    responsable =
      Repo.one!(
        from(u in "aauth_users",
          where: u.id == ^user_id,
          select: %{full_name: u.full_name, id: u.id}
        )
      )

    client = Staff.get_one_client(client_id_commande)
    current_shift_id = 1
    attrs = %{products: Jason.decode!(products)}

    attrs =
      Map.update(attrs, :products, [], &build_products/1)
      |> Map.put(:cashier_shifts_id, current_shift_id)

    {:ok, kitchen_pid} = Agent.start_link(fn -> [] end)
    {:ok, mainbar_pid} = Agent.start_link(fn -> [] end)
    {:ok, restobar_pid} = Agent.start_link(fn -> [] end)

    [to_save_details, to_save_flow] =
      transform_products_update(
        is_acc,
        [kitchen_pid, mainbar_pid, restobar_pid, attrs.products],
        client,
        cmd_id,
        cmd_code,
        responsable
      )

    insert_cmd_details(to_save_details)
    send_bon_cmd([kitchen_pid, mainbar_pid, restobar_pid])
    insert_stock_flow(to_save_flow)
  end

  defp send_bon_cmd([kit_pid, main_pid, resto_pid]) do
    kitchen_prod = Agent.get(kit_pid, fn state -> state end)
    mainbar_prod = Agent.get(main_pid, fn state -> state end)
    restobar_prod = Agent.get(resto_pid, fn state -> state end)

    if Enum.count(kitchen_prod) > 0 do
      KitchenPrint.add_new_bon_items(kitchen_prod)
    end

    if Enum.count(mainbar_prod) > 0 do
      RestoBarPrint.add_new_bon_items(mainbar_prod)
    end

    if Enum.count(restobar_prod) > 0 do
      MainBarPrint.add_new_bon_items(restobar_prod)
    end

    Agent.stop(kit_pid)
    Agent.stop(main_pid)
    Agent.stop(resto_pid)
  end

  defp transform_products_update(
         is_acc,
         [kit_pid, main_pid, resto_pid, products],
         client,
         cmd_id,
         cmd_code,
         responsable
       ) do
    cmd_products = get_cmd_products(cmd_id) |> Enum.map(fn p -> {cmd_id, p.article_codebar} end)

    to_save_detail =
      Enum.map(products, fn p ->
        codebar =
          if is_acc do
            "POS/" <> p.codebar
          else
            p.codebar
          end

        if(Enum.member?(cmd_products, {cmd_id, codebar})) do
          from(c in "restaurant_ibi_commandes_produits",
            update: [inc: [quantite: ^p.quantite, prix_total: ^p.quantite * ^p.prix]],
            where: c.restaurant_ibi_commandes_id == ^cmd_id and c.ref_product_codebar == ^codebar
          )
          |> Repo.update_all([])

          prod = %{
            restaurant_ibi_commandes_id: cmd_id,
            ref_product_codebar: p.codebar,
            ref_command_code: cmd_code,
            quantite: p.quantite,
            prix: p.prix,
            prix_total: p.prix_total,
            discount_percent: Staff.get_discount_percent(p.type_article, client),
            name: p.name,
            # TODO: change to a real user
            created_by_restaurant_ibi_commandes_produits: responsable.id,
            store_id_restaurant_ibi_commandes_produits: p.store_id,
            client_file_id_commandes_produits: client.client_file_id
          }

          prepare_bon_cmd([kit_pid, main_pid, resto_pid], p, prod, responsable)
          nil
        else
          prod = %{
            restaurant_ibi_commandes_id: cmd_id,
            ref_product_codebar:
              if is_acc do
                "POS/" <> p.codebar
              else
                p.codebar
              end,
            ref_command_code: cmd_code,
            quantite: p.quantite,
            prix:
              if is_acc do
                0
              else
                p.prix
              end,
            prix_total:
              if is_acc do
                0
              else
                p.prix_total
              end,
            discount_percent: Staff.get_discount_percent(p.type_article, client),
            name:
              if is_acc do
                p.name <> " (Accomp.)"
              else
                p.name
              end,
            # TODO: change to a real user
            created_by_restaurant_ibi_commandes_produits: responsable.id,
            store_id_restaurant_ibi_commandes_produits: p.store_id,
            client_file_id_commandes_produits: client.client_file_id
          }

          prepare_bon_cmd([kit_pid, main_pid, resto_pid], p, prod, responsable)

          prod
        end
      end)

    to_save_detail = Enum.reject(to_save_detail, fn p -> is_nil(p) end)

    to_save_flow =
      Enum.map(products, fn p ->
        %{
          ref_article_barcode_sf: p.codebar,
          quantite_sf: p.quantite,
          ref_command_code_sf: cmd_code,
          type_sf:
            if is_acc do
              "accompagnement"
            else
              "sale"
            end,
          unit_price_sf:
            if is_acc do
              0
            else
              p.prix
            end,
          total_price_sf:
            if is_acc do
              0
            else
              Decimal.to_integer(p.prix) * p.quantite
            end,
          created_by_sf: responsable.id,
          store_id: p.store_id
        }
      end)

    [to_save_detail, to_save_flow]
  end

  defp prepare_bon_cmd([kit_pid, main_pid, resto_pid], p, prod, responsable) do
    cond do
      p.store_id == 2 || p.store_id == "2" ->
        prod = Map.put_new(prod, :responsable, responsable.full_name)

        Agent.cast(kit_pid, fn state ->
          state ++ [prod]
        end)

      p.store_id == 4 || p.store_id == "4" ->
        prod = Map.put_new(prod, :responsable, responsable.full_name)

        Agent.cast(main_pid, fn state ->
          state ++ [prod]
        end)

      p.store_id == 5 || p.store_id == "5" ->
        prod = Map.put_new(prod, :responsable, responsable.full_name)

        Agent.cast(resto_pid, fn state ->
          state ++ [prod]
        end)

      true ->
        nil
    end
  end

  defp transfrom_products(
         [kit_pid, main_pid, resto_pid, products],
         client,
         cmd_id,
         cmd_code,
         responsable
       ) do
    to_save_details =
      Enum.map(products, fn p ->
        prod = %{
          restaurant_ibi_commandes_id: cmd_id,
          ref_product_codebar: p.codebar,
          ref_command_code: cmd_code,
          quantite: p.quantite,
          prix: p.prix,
          prix_total: p.prix_total,
          discount_percent: Staff.get_discount_percent(p.type_article, client),
          name: p.name,
          # TODO: change to a real user
          created_by_restaurant_ibi_commandes_produits: 1,
          store_id_restaurant_ibi_commandes_produits: p.store_id,
          client_file_id_commandes_produits: client.client_file_id
        }

        prepare_bon_cmd([kit_pid, main_pid, resto_pid], p, prod, responsable)

        prod
      end)

    to_save_flow =
      Enum.map(products, fn p ->
        %{
          ref_article_barcode_sf: p.codebar,
          quantite_sf: p.quantite,
          ref_command_code_sf: cmd_code,
          type_sf: "sale",
          unit_price_sf: p.prix,
          total_price_sf: Decimal.to_integer(p.prix) * p.quantite,
          created_by_sf: 1,
          store_id: p.store_id
        }
      end)

    [to_save_details, to_save_flow]
  end

  def create_order_from_split(
        %{
          "user_id" => user_id,
          "shift_id" => shift_id,
          "order_time" => order_time,
          "products" => products
        } \\ %OrderData{}
      ) do
    user_id = user_id

    current_shift_id = shift_id

    attrs = %{products: products}

    attrs =
      Map.update(attrs, :products, [], &build_products/1)
      |> Map.put(:cashier_shifts_id, current_shift_id)

    cmd_code = make_ordercode()

    Repo.insert_all(
      "restaurant_ibi_commandes",
      [
        %{
          code: cmd_code,
          # this will be the id of the default client
          client_id_commande: 1,
          tva: 18,
          created_by_restaurant_ibi_commandes: user_id,
          date_creation_restaurant_ibi_commandes: order_time,
          id_cashier_shift: current_shift_id
        }
      ]
    )

    last_cmd =
      Repo.one(
        from c in "restaurant_ibi_commandes",
          where: c.created_by_restaurant_ibi_commandes == ^user_id,
          order_by: [desc: c.id_restaurant_ibi_commandes],
          select: %{id: c.id_restaurant_ibi_commandes},
          limit: 1
      )

    cmd_id =
      if last_cmd == nil do
        1
      else
        last_cmd.id
      end

    # prevent a column to be negative
    # ALTER TABLE Branch ADD CONSTRAINT chkassets CHECK (assets > 0);
    to_save_details =
      Enum.map(attrs.products, fn p ->
        %{
          restaurant_ibi_commandes_id: cmd_id,
          ref_product_codebar: p.codebar,
          ref_command_code: cmd_code,
          quantite: p.quantite,
          prix: p.prix,
          prix_total: p.prix_total,
          discount_percent:
            Staff.get_discount_percent(p.type_article, %{discount_food: 0, discount_boisson: 0}),
          name: p.name,
          # TODO: change to a real user
          created_by_restaurant_ibi_commandes_produits: 1,
          store_id_restaurant_ibi_commandes_produits: p.store_id,
          client_file_id_commandes_produits: 1
        }
      end)

    insert_cmd_details(to_save_details)
  end

  def request_void_cmd(cmd_id) do
    cmd_tab = Const.commandes()

    update =
      from(c in cmd_tab,
        update: [set: [commande_void_request: 1]],
        where: c.id_restaurant_ibi_commandes == ^cmd_id
      )
      |> Repo.update_all([])

    update
  end

  def cancel_void_request(cmd_id) do
    cmd_tab = Const.commandes()

    update =
      from(c in cmd_tab,
        update: [set: [commande_void_request: 0]],
        where: c.id_restaurant_ibi_commandes == ^cmd_id and c.commande_status == 0
      )
      |> Repo.update_all([])

    update
  end

  def request_split_cmd(cmd_id) do
    cmd_tab = Const.commandes()

    update =
      from(c in cmd_tab,
        update: [set: [commande_split_request: 1]],
        where: c.id_restaurant_ibi_commandes == ^cmd_id
      )
      |> Repo.update_all([])

    update
  end

  def see_all_void_request() do
    cmd_tab = Const.commandes()
    users = Const.users()

    from(c in cmd_tab,
      join: u in ^users,
      on: u.id == c.created_by_restaurant_ibi_commandes,
      where: c.commande_void_request == 1 and c.commande_status == 0,
      select: %{
        user_name: u.full_name,
        ordered_at: c.date_creation_restaurant_ibi_commandes,
        order_code: c.code
      }
    )
  end

  def get_cmd_products(cmd_id) do
    cmd_prod = Const.commandes_produits()

    list =
      from(
        prod in cmd_prod,
        where: prod.restaurant_ibi_commandes_id == ^cmd_id,
        select: %{
          prod_id: prod.id_restaurant_ibi_commandes_produits,
          quantite: prod.quantite,
          article_codebar: prod.ref_product_codebar,
          prix: prod.prix,
          discount: prod.discount_percent,
          name: prod.name
        }
      )
      |> Repo.all()

    list
  end

  def split_to_new_bill(%{
        "created_by" => user_id,
        "products" => products,
        "client_id" => client_id,
        "order_time" => order_time,
        "shift_id" => shift_id
      }) do
    cmd_prods = Const.commandes_produits()

    Enum.each(products, fn prod ->
      from(p in cmd_prods,
        where: p.id_restaurant_ibi_commandes_produits == ^prod["cmd_prod_id"],
        update: [set: [quantite: -(^prod["sold_quantity"])]]
      )
      |> Repo.update_all([])
    end)

    create_order_from_split(%{
      "client_id_commande" => client_id,
      "products" => products,
      "user" => user_id,
      "order_time" => order_time,
      "shift_id" => shift_id
    })
  end

  def send_transfer_request(cmd_id, to_waiter_id) do
    cmd_tab = Const.commandes()

    update_transfer =
      from(c in cmd_tab,
        update: [set: [transfer_to: ^to_waiter_id]],
        where: c.id_restaurant_ibi_commandes == ^cmd_id
      )
      |> Repo.update_all([])

    update_transfer
  end

  def confirm_transfer_request(cmd_id) do
    cmd_tab = Const.commandes()
    now = NaiveDateTime.to_iso8601(NaiveDateTime.local_now())

    confirm_transfer =
      from(c in cmd_tab,
        where: c.id_restaurant_ibi_commandes == ^cmd_id,
        update: [
          set: [
            transfer_status: 1,
            transfer_accepted_at: ^now
          ]
        ]
      )
      |> Repo.update_all([])

    confirm_transfer
  end

  def cancel_transfer_request(cmd_id) do
    cmd_tab = Const.commandes()

    cancel_transfer =
      from(c in cmd_tab,
        where: c.id_restaurant_ibi_commandes == ^cmd_id,
        update: [
          set: [transfer_status: 0, transfer_to: 0]
        ]
      )
      |> Repo.update_all([])

    cancel_transfer
  end

  defp insert_stock_flow(to_save_flow) do
    Enum.each(to_save_flow, fn flow ->
      {store_id, new_map} = Map.pop!(flow, :store_id)
      stock_tab = "restaurant_store_" <> Integer.to_string(store_id) <> "_ibi_articles_stock_flow"
      article_tab = "restaurant_store_" <> Integer.to_string(store_id) <> "_ibi_articles"

      from(a in article_tab,
        where: a.codebar_article == ^flow.ref_article_barcode_sf,
        update: [inc: [quantity_article: -(^flow.quantite_sf)]]
      )
      |> Repo.update_all([])

      Repo.insert_all(stock_tab, [new_map])
    end)

    {:ok, message: "order placed with success!"}
  end

  defp insert_cmd_details(order_details) do
    IO.inspect(order_details)
    IO.puts("inserting in details...")
    Repo.insert_all("restaurant_ibi_commandes_produits", order_details)
  end

  defp make_ordercode() do
    #! TODO: must be according to the current here
    today = Date.to_iso8601(Date.utc_today(), :basic)
    day = Date.day_of_week(Date.utc_today()) |> Integer.to_string()

    case Repo.one(
           from(x in "restaurant_ibi_commandes",
             order_by: [desc: x.id_restaurant_ibi_commandes],
             select: %{
               code: x.code,
               id: x.id_restaurant_ibi_commandes
             },
             limit: 1
           )
         ) do
      %{} = order ->
        indice =
          String.split(order.code, "/")
          |> Enum.reverse()
          |> Enum.at(0)

        IO.inspect(indice)
        current_indice = String.to_integer(indice) + 1

        code = "#{today}/#{day}/#{current_indice}"
        code

      nil ->
        "#{today}/#{day}/0"
    end
  end

  defp build_products(products) do
    for product <- products do
      article_tab = Const.articles(product["store_id"])

      prod =
        Repo.one!(
          from(a in article_tab,
            where: a.id_article == ^product["item_id"],
            select: %{
              prod_name: a.design_article,
              codebar: a.codebar_article,
              store_id: a.store_id_article,
              categorie_id: a.ref_categorie_article,
              price: a.prix_de_vente_article,
              id: a.id_article,
              type_article: a.type_article
            }
          )
        )

      %{
        quantite: product["sold_quantity"],
        prix: prod.price,
        codebar: prod.codebar,
        id: product["item_id"],
        store_id: product["store_id"],
        name: prod.prod_name,
        type_article: prod.type_article,
        prix_total: product["sold_quantity"] * Decimal.to_integer(prod.price),
        category_id: prod.categorie_id
      }
    end
  end
end
