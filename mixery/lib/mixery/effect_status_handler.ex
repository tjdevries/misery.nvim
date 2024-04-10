defmodule Mixery.EffectStatusHandler do
  use GenServer

  require Logger

  import Ecto.Query

  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Effect
  alias Mixery.EffectStatus

  @rewrite_enabled false

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Mixery.subscribe_to_neovim_connection_events()

    statuses =
      Effect
      |> Repo.all()
      |> Map.new(fn effect ->
        case effect.enabled_on do
          :always -> {effect.id, {true, effect}}
          :rewrite -> {effect.id, {false, effect}}
          :neovim -> {effect.id, {false, effect}}
          :never -> {effect.id, {false, effect}}
        end
      end)

    state = %{connections: [], statuses: statuses}
    {:ok, state}
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: [] = connections}, state) do
    state = emit_neovim_statuses(state, false)
    {:noreply, state |> Map.put(:connections, connections)}
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: connections}, state) do
    state =
      case state[:connections] do
        [] -> emit_neovim_statuses(state, true)
        _ -> state
      end

    {:noreply, state |> Map.put(:connections, connections)}
  end

  @impl true
  def handle_call({:effect_status, effect_id}, _from, state) do
    {:reply, state.statuses[effect_id], state}
  end

  @impl true
  def handle_call(:effect_statuses, _from, state) do
    {:reply, state.statuses, state}
  end

  def get_all_effect_statuses() do
    query =
      from es in EffectStatus,
        select: es.effect_id,
        where: es.status == ^:enabled,
        distinct: es.effect_id

    Repo.all(query)
  end

  defp emit_neovim_statuses(state, status) do
    query =
      from eff in Effect,
        where: eff.enabled_on == ^:neovim or (^@rewrite_enabled and eff.enabled_on == ^:rewrite)

    statuses =
      query
      |> Repo.all()
      |> Enum.reduce(state.statuses, fn effect, statuses ->
        Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: status})
        Map.put(statuses, effect.id, {status, effect})
      end)

    state |> Map.put(:statuses, statuses)
  end
end
