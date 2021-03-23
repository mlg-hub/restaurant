defmodule Restaurant.System.KitchenPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :kitchen, module: __MODULE__
end

defmodule Restaurant.System.MainBarPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :main_bar, module: __MODULE__
end

defmodule Restaurant.System.RestoBarPrint do
  use Restaurant.System.Cache.PrintBluePrint, departement: :resto_bar, module: __MODULE__
end
