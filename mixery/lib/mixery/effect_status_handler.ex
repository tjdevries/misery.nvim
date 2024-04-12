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
    emit_neovim_statuses(false)
    {:noreply, state |> Map.put(:connections, connections)}
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: connections}, state) do
    case state[:connections] do
      [] -> emit_neovim_statuses(true)
      _ -> nil
    end

    {:noreply, state |> Map.put(:connections, connections)}
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

  defp emit_neovim_statuses(status) do
    query =
      from eff in Effect,
        where: eff.enabled_on == ^:neovim or (^@rewrite_enabled and eff.enabled_on == ^:rewrite)

    query
    |> Repo.all()
    |> Enum.each(fn effect ->
      Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: status})
    end)
  end
end
