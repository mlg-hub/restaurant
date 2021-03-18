defmodule Restaurant.Models.OrderProduct do
  defstruct [:item_id, :sold_quantity, :store_id]
end

defmodule Restaurant.Models.OrderData do
  alias Restaurant.Models.OrderProduct

  defstruct products: [%OrderProduct{}],
            tva: nil,
            client_id_commande: nil,
            code: nil,
            commande_status: 0,
            created_by_restaurant_ibi_commandes: nil
end

defmodule Restaurant.Models.Article do
  defstruct [:ID_STORE, :NAME_STORE]
end
