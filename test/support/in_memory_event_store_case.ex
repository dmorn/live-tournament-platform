defmodule LTP.InMemoryEventStoreCase do
  use ExUnit.CaseTemplate

  setup do
    {:ok, _apps} = Application.ensure_all_started(:ltp)

    on_exit(fn ->
      :ok = Application.stop(:ltp)
    end)
  end
end
