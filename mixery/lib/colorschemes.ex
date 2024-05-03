defmodule Mixery.Colorschemes do
  use GenServer

  @table __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list do
    @table
    |> :ets.tab2list()
    |> Enum.map(fn {colorscheme} -> colorscheme end)
  end

  def insert_many(colorschemes) do
    GenServer.call(@table, {:insert, colorschemes})
  end

  @impl GenServer
  def init([]) do
    table = :ets.new(@table, [:named_table, :public, :set, {:read_concurrency, true}])
    {:ok, table}
  end

  @impl GenServer
  def handle_call({:insert, colorschemes}, _from, table) do
    true = :ets.insert(table, Enum.map(colorschemes, &{&1}))
    {:reply, :ok, table}
  end
end
