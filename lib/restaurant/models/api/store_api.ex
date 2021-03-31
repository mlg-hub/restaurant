defmodule Restaurant.Model.Api.Store do
  import Ecto.Query
  alias Restaurant.Repo
  alias Restaurant.Helpers.Const

  def get_all_stores do
    table = Const.stores_table()

    from(s in table,
      where: s.is_pos == 1 and s.delete_status_store == 0,
      select: %{id_store: s.id_store, store_name: s.name_store}
    )
    |> Repo.all()
  end

  def get_all_stores_complete() do
    all_stores = get_all_stores()

    all_store_complete =
      Enum.map(all_stores, fn st ->
        IO.inspect(st.id_store)
        articles = Const.articles(st.id_store)
        categories = Const.categories()
        table = Const.stores_table()

        store_data =
          from(s in table,
            join: c in ^categories,
            on: c.store_id == s.id_store,
            join: a in ^articles,
            on: a.ref_categorie_article == c.id_categorie,
            where: s.id_store == ^st.id_store,
            select: %{
              store_id: s.id_store,
              store_name: s.name_store,
              articles: %{
                article_name: a.design_article,
                article_id: a.id_article,
                type: a.type_article,
                codebar: a.codebar_article,
                categorie_id: a.ref_categorie_article,
                quantity: a.quantity_article,
                price: a.prix_de_vente_article,
                article_store: s.id_store
              },
              cat_name: c.nom_categorie,
              cat_id: c.id_categorie
            }
          )
          |> Repo.all()

        if Enum.count(store_data) > 0 do
          first = Enum.at(store_data, 0)

          store_info = %{store_id: first.store_id, store_name: first.store_name}
          store_data_info = transform_store_data(store_data, %{categories: []})
          Map.merge(store_info, store_data_info)
        end
      end)

    all_store_complete
  end

  defp transform_store_data([head | tail], acc) do
    struc_data = structure_data(head, acc)
    transform_store_data(tail, struc_data)
  end

  defp transform_store_data([], acc) do
    %{categories: acc.categories}
  end

  defp structure_data(data, acc) do
    categorie_index =
      Enum.find_index(acc.categories, fn x ->
        x.categorie_id == data.articles.categorie_id
      end)

    if categorie_index != nil do
      categories_map = Enum.at(acc.categories, categorie_index)

      acc1 = %{categories_map | articles: categories_map.articles ++ [data.articles]}
      new_list = List.replace_at(acc.categories, categorie_index, acc1)

      %{categories: new_list}
    else
      acc1 = [
        %{categorie_id: data.cat_id, categorie_name: data.cat_name, articles: [data.articles]}
      ]

      %{categories: acc.categories ++ acc1}
    end
  end
end
