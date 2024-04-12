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

    Effect
    |> Repo.all()
    |> Enum.each(fn effect ->
      case effect.enabled_on do
        :never ->
          %EffectStatus{
            effect_id: effect.id,
            status: :disabled
          }
          |> EffectStatus.changeset(%{})
          |> Repo.insert!()

        _ ->
          nil
      end
    end)

    state = %{connections: []}
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
    status_subquery =
      from status in EffectStatus,
        group_by: status.effect_id,
        having: fragment("max(?)", status.inserted_at),
        order_by: status.effect_id,
        select: %{effect_id: status.effect_id, status: status.status}

    query =
      from effect in Effect,
        join: status in subquery(status_subquery),
        on: effect.id == status.effect_id,
        select: {status.status, effect}

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
