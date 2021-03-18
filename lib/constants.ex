defmodule Restaurant.Helpers.Const do
  @preffix "restaurant_ibi_"
  @preffix_store "restaurant_store_"
  @preffix_resto "restaurant_"

  def stores_table do
    @preffix <> "stores"
  end

  def categories() do
    @preffix <> "articles_categories"
  end

  def articles(store_id) do
    @preffix_store <> "#{store_id}" <> "_ibi_articles"
  end

  def users do
    "aauth_users"
  end

  def clients_tab do
    @preffix_resto <> "clients"
  end

  def client_file_tab do
    "client_file"
  end

  def commandes do
    @preffix <> "commandes"
  end

  def commandes_produits do
    @preffix <> "commandes_produits"
  end

  def mode_payments do
   "mode_paiement"
  end

  def type_facture do
    "type_facture"
  end
end
