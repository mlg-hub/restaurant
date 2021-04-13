# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Restaurant.Repo.insert!(%Restaurant.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
bon1 = {"20210411/7/30612:55:55", "pending",
    [
      %{
        client_file_id_commandes_produits: 1,
        code_stamp: "20210411/7/30612:55:55",
        created_by_restaurant_ibi_commandes_produits: 746,
        discount_percent: 0,
        name: "SPARKLING WATER 400 CL",
        order_time: "12:55:55",
        prix: #Decimal<2500>,
        prix_total: 2500,
        quantite: 1,
        ref_command_code: "20210411/7/306",
        ref_product_codebar: "B2000157",
        responsable: "Claude",
        restaurant_ibi_commandes_id: "307",
        store_id_restaurant_ibi_commandes_produits: 5
      }
    ]
  }
bon2 = {"20210411/7/30913:56:57", "pending",
[
  %{
    client_file_id_commandes_produits: 1,
    code_stamp: "20210411/7/30913:56:57",
    created_by_restaurant_ibi_commandes_produits: 726,
    discount_percent: 0,
    name: "PURE WATER SMALL 600 CL",
    order_time: "13:56:57",
    prix: #Decimal<2000>,
    prix_total: 2000,
    quantite: 1,
    ref_command_code: "20210411/7/309",
    ref_product_codebar: "B2000158",
    responsable: "kevin niyonzima",
    restaurant_ibi_commandes_id: 310,
    store_id_restaurant_ibi_commandes_produits: 5
  }
]}

bon3 =  {"20210411/7/30413:11:08", "pending",
[
  %{
    client_file_id_commandes_produits: 1,
    code_stamp: "20210411/7/30413:11:08",
    created_by_restaurant_ibi_commandes_produits: 726,
    discount_percent: 0,
    name: "PURE WATER SMALL 600 CL",
    order_time: "13:11:08",
    prix: #Decimal<2000>,
    prix_total: 2000,
    quantite: 1,
    ref_command_code: "20210411/7/304",
    ref_product_codebar: "B2000158",
    responsable: "kevin niyonzima",
    restaurant_ibi_commandes_id: "305",
    store_id_restaurant_ibi_commandes_produits: 5
  }
]}

bon4 = {"20210411/7/30713:06:57", "pending",
[
  %{
    client_file_id_commandes_produits: 1,
    code_stamp: "20210411/7/30713:06:57",
    created_by_restaurant_ibi_commandes_produits: 726,
    discount_percent: 0,
    name: "PURE WATER SMALL 600 CL",
    order_time: "13:06:57",
    prix: #Decimal<2000>,
    prix_total: 4000,
    quantite: 2,
    ref_command_code: "20210411/7/307",
    ref_product_codebar: "B2000158",
    responsable: "kevin niyonzima",
    restaurant_ibi_commandes_id: 308,
    store_id_restaurant_ibi_commandes_produits: 5
  }
]}

bon5 =
  {"20210411/7/29911:08:26", "pending",
   [
     %{
       client_file_id_commandes_produits: 1,
       code_stamp: "20210411/7/29911:08:26",
       created_by_restaurant_ibi_commandes_produits: 726,
       discount_percent: 0,
       name: "CAPPUCCINO",
       order_time: "11:08:26",
       prix: #Decimal<4800>,
       prix_total: 9600,
       quantite: 2,
       ref_command_code: "20210411/7/299",
       ref_product_codebar: "0001-000390",
       responsable: "kevin niyonzima",
       restaurant_ibi_commandes_id: 300,
       store_id_restaurant_ibi_commandes_produits: 8
     }
   ]}

   bon6 =  {"20210411/7/30412:10:08", "pending",
   [
     %{
       client_file_id_commandes_produits: 1,
       code_stamp: "20210411/7/30412:10:08",
       created_by_restaurant_ibi_commandes_produits: 726,
       discount_percent: 0,
       name: "ZANZI COFFEE",
       order_time: "12:10:08",
       prix: #Decimal<5000>,
       prix_total: 5000,
       quantite: 1,
       ref_command_code: "20210411/7/304",
       ref_product_codebar: "0001-000429",
       responsable: "kevin niyonzima",
       restaurant_ibi_commandes_id: "305",
       store_id_restaurant_ibi_commandes_produits: 8
     },
     %{
       client_file_id_commandes_produits: 1,
       created_by_restaurant_ibi_commandes_produits: 726,
       discount_percent: 0,
       name: "CAPPUCCINO",
       order_time: "12:10:08",
       prix: #Decimal<4800>,
       prix_total: 4800,
       quantite: 1,
       ref_command_code: "20210411/7/304",
       ref_product_codebar: "0001-000390",
       responsable: "kevin niyonzima",
       restaurant_ibi_commandes_id: "305",
       store_id_restaurant_ibi_commandes_produits: 8
     }
   ]}

   bon7 =  {"20210411/7/29109:46:43", "used",
   [
     %{
       client_file_id_commandes_produits: 1,
       code_stamp: "20210411/7/29109:46:43",
       created_by_restaurant_ibi_commandes_produits: 726,
       discount_percent: 0,
       name: "BREAK FAST HAGA",
       order_time: "09:46:43",
       prix: #Decimal<10000>,
        quantite: 1,
         ref_command_code: "20210411/7/291",
        ref_product_codebar: "0001-000290",
         responsable: "kevin niyonzima",
         restaurant_ibi_commandes_id: 294,
         store_id_restaurant_ibi_commandes_produits: 2
     }
   ]}
