defmodule Restaurant.System.Cache.PrintBluePrint do
  defmacro __using__(opts) do
    {:ok, dpt} = Keyword.fetch(opts, :departement)
    {:ok, module} = Keyword.fetch(opts, :module)

    quote do
      use GenServer
      alias RestaurantWeb.Presence
      require Logger
      alias Restaurant.System.Struct.Bon

      def start_link(_) do
        GenServer.start_link(unquote(module), nil, name: unquote(module))
      end

      def init(_) do
        Process.flag(:trap_exit, true)
        Process.send_after(self(), :init_dpt, 1000)
        {:ok, nil}
      end

      def add_new_bon_items(%Bon{} = bon_items) do
        GenServer.call(unquote(module), {:insert_bon_items, bon_items})
      end

      def set_bon_used(transaction_code) do
        GenServer.cast(unquote(module), {:set_bon_used, transaction_code})
      end

      def get_all_bons() do
        GenServer.call(unquote(module), :get_bons)
      end

      def get_all_bons_status(status) do
        GenServer.call(unquote(module), {:get_all_bons, status})
      end

      def handle_call({:insert_bon_items, %Bon{} = bon_items}, _from, state) do
        ets_tab = Map.get(state, :ets_tab)
        time_stamp = Time.utc_now() |> Time.to_string()
        code_stamp = bon_items.code <> time_stamp

        if ets_tab != nil do
          :ets.insert(ets_tab, {code_stamp, "pending", bon_items})
          myself = self()

          spawn(fn ->
            GenServer.cast(myself, {:dets_insert_bon_items, {code_stamp, "pending", bon_items}})
          end)

          {:reply, {:ok, "Bon Inserted nice"}}
        end
      end

      def handle_call({:get_all_bons, status}, _from, state) do
        case Map.get(state, :ets_tab) do
          nil ->
            {:reply, {:ok, []}, state}

          table_name ->
            bons_func =
              :ets.fun2ms(fn {_, status_in, _} = bons when status_in == status -> bons end)

            results = :ets.select(table_name, bons_func)
            {:reply, {:ok, results}, state}
        end
      end

      def handle_call(:get_bons, _from, state) do
        case Map.get(state, :ets_tab) do
          nil ->
            {:reply, {:ok, []}, state}

          table_name ->
            bons_data = :ets.tab2list(table_name)
            {:reply, {:ok, bons_data}, state}
        end
      end

      def handle_cast({:set_bon_used, transaction_code}, state) do
        case Map.get(state, :ets_tab) do
          nil ->
            {:reply, {:error, "not updated"}, state}

          table_name ->
            # search for the bon de commande
            [{_, _, bon_items}] = :ets.lookup(table_name, transaction_code)
            update_ets = :ets.update_element(table_name, transaction_code, {2, "used"})

            if update_ets do
              Process.send_after(self(), {:dets_set_bon_used, transaction_code, bon_items}, 1000)
            end

            {:reply, {:ok, "may have been updated"}}
        end
      end

      def handle_cast({:dets_insert_bon_items, {code_stamp, status, items}}, state) do
        Logger.warn("Insertion in Dets")
        dets_table = Map.get(state, :dets_tab)

        case dets_table do
          nil ->
            nil
            {:noreply, state}

          table_name ->
            tab_name = Atom.to_string(unquote(dpt))
            :dets.open_file(tab_name, [{:file, '#{tab_name}_db.txt'}])

            :dets.insert(
              table_name,
              {code_stamp, status, items}
            )

            :dets.close(unquote(dpt))
            {:noreply, state}
        end

        {:noreply, state}
      end

      def handle_info({:dets_set_bon_used, transaction_code, bon_items}, state) do
        dets_table = Map.get(state, :dets_tab)

        case dets_table do
          nil ->
            nil

          tab_name ->
            dpt_name = Atom.to_string(unquote(dpt))
            :dets.open_file(dpt_name, [{:file, '#{dpt_name}_db.txt'}])

            :dets.delete(tab_name, transaction_code)
            :dets.insert_new(tab_name, {transaction_code, "pending", bon_items})
        end

        {:noreply, state}
      end

      def handle_info(:init_dpt, _state) do
        Logger.warn("Initiating the #{unquote(dpt)} storage...")
        tab_name = Atom.to_string(:tres)
        :dets.open_file(tab_name, [{:file, '#{tab_name}_db.txt'}, {:type, :set}])
        tab_ets = :ets.new(unquote(dpt), [:set, :protected, :named_table])
        :dets.to_ets(unquote(dpt), tab_ets)
        :dets.close(unquote(dpt))
        %{ets_tab: tab_ets, dets_tab: unquote(dpt)}
        {:noreply, %{ets_tab: tab_ets, dets_tab: unquote(dpt)}}
      end

      def terminate(reason, state) do
        Logger.warn("Terminating the #{unquote(dpt)} storage")
        IO.inspect(reason)
        tab_name = Atom.to_string(unquote(dpt))

        spawn(fn dept = unquote(dpt) ->
          tab_name = Atom.to_string(dept)
          :dets.open_file(tab_name, [{:file, '#{tab_name}_db.txt'}])
          :ets.to_dets(dept, tab_name)
          :dets.close(dept)
        end)

        {:noreply, state}
      end
    end
  end
end
