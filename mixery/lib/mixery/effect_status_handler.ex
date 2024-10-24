defmodule Mixery.EffectStatusHandler do
  use GenServer

  require Logger

  import Ecto.Query

  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Effect
  alias Mixery.EffectStatus
  alias Mixery.EffectLedger

  @rewrite_enabled false

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Mixery.subscribe_to_neovim_connection_events()
    Mixery.subscribe_to_neovim_events()

    Effect
    |> Repo.all()
    |> Enum.each(fn effect ->
      case effect.enabled_on do
        :always ->
          %EffectStatus{
            effect_id: effect.id,
            status: :enabled
          }
          |> EffectStatus.changeset(%{})
          |> Repo.insert!()

        _ ->
          %EffectStatus{
            effect_id: effect.id,
            status: :disabled
          }
          |> EffectStatus.changeset(%{})
          |> Repo.insert!()
      end
    end)

    state = %{connections: []}
    {:ok, state}
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: [] = connections}, state) do
    emit_neovim_statuses(:disabled)
    {:noreply, state |> Map.put(:connections, connections)}
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: connections}, state) do
    case state[:connections] do
      [] -> emit_neovim_statuses(:enabled)
      _ -> nil
    end

    {:noreply, state |> Map.put(:connections, connections)}
  end

  def handle_info(%Event.ExecuteEffectCompleted{execution_id: execution_id}, state) do
    execution = Repo.get!(EffectLedger, execution_id)

    execution
    |> Ecto.Changeset.change(status: :completed)
    |> Repo.update!()

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def get_all_effect_statuses() do
    # status_subquery =
    #   from status in EffectStatus,
    #     group_by: status.effect_id,
    #     having: status.inserted_at == fragment("max(?)", status.inserted_at),
    #     order_by: status.effect_id,
    #     select: %{effect_id: status.effect_id, status: status.status}

    status_subquery =
      from status in EffectStatus,
        as: :status,
        where:
          not exists(
            from s in EffectStatus,
              where:
                parent_as(:status).effect_id == s.effect_id and
                  parent_as(:status).inserted_at < s.inserted_at
          ),
        select: %{effect_id: status.effect_id, status: status.status}

    # status_subquery =
    #   from status in EffectStatus,
    #     as: :status,
    #     where:
    #       not exists(
    #         from(s in EffectStatus,
    #           where:
    #             parent_as(:status).effect_id == s.effect_id and
    #               parent_as(:status).inserted_at < s.inserted_at
    #         ),
    #         select: %{effect_id: status.effect_id, status: status.status}
    #       )

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

      %EffectStatus{effect_id: effect.id, status: status}
      |> EffectStatus.changeset(%{})
      |> Repo.insert!()
    end)
  end
end
