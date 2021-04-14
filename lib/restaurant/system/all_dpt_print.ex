defmodule Restaurant.System.KitchenPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :kitchen, module: __MODULE__
end

defmodule Restaurant.System.MainBarPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :mainbar, module: __MODULE__
end

defmodule Restaurant.System.MiniBarPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :minibar, module: __MODULE__
end

defmodule Restaurant.System.RestaurantPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :restaurant, module: __MODULE__
end
