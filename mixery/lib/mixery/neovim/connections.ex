defmodule Mixery.Neovim.Connections do
  use GenServer

  require Logger

  alias Mixery.Event

  # ----------------------------------------------------------------------------
  # Public API
  # ----------------------------------------------------------------------------

  def start_link(args) do
    Logger.info("[ConnectionTracker] starting...")
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def add_connection(pid) do
    GenServer.cast(__MODULE__, {:add_connection, pid})
  end

  def remove_connection(pid) do
    GenServer.cast(__MODULE__, {:remove_connection, pid})
  end

  # ----------------------------------------------------------------------------
  # GenServer Callbacks
  # ----------------------------------------------------------------------------

  @impl true
  def init(_args) do
    state = %{connections: []}

    Mixery.broadcast_event(%Event.NeovimConnection{connections: state.connections})

    {:ok, state}
  end

  @impl true
  def handle_cast({:add_connection, pid}, state) do
    Logger.info("[ConnectionTracker] adding connection: #{inspect(pid)}")
    connections = [pid | state.connections]

    Mixery.broadcast_event(%Event.NeovimConnection{connections: connections})

    {:noreply, %{state | connections: connections}}
  end

  @impl true
  def handle_cast({:remove_connection, pid}, state) do
    Logger.info("[ConnectionTracker] removing connection: #{inspect(pid)}")
    connections = List.delete(state.connections, pid)

    Mixery.broadcast_event(%Event.NeovimConnection{connections: connections})

    {:noreply, %{state | connections: connections}}
  end

  @impl true
  def handle_call(:has_active_connections, _from, state) do
    {:reply, state.connections != [], state}
  end

  def connected?() do
    GenServer.call(__MODULE__, :has_active_connections)
  end
end
