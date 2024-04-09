defmodule Mixery.RewardHandler do
  use GenServer

  require Logger

  import Ecto.Query

  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch.ChannelReward

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Mixery.subscribe_to_neovim_connection_events()

    statuses =
      ChannelReward
      |> Repo.all()
      |> Map.new(fn reward ->
        case reward.enabled_on do
          :always -> {reward.id, true}
          :neovim -> {reward.id, false}
          :never -> {reward.id, false}
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
  def handle_call({:reward_status, reward_id}, _from, state) do
    {:reply, state.statuses[reward_id], state}
  end

  def get_reward_status(reward) do
    GenServer.call(__MODULE__, {:reward_status, reward.id})
  end

  @impl true
  def handle_call(:reward_statuses, _from, state) do
    {:reply, state.statuses, state}
  end

  def get_all_reward_statuses() do
    GenServer.call(__MODULE__, :reward_statuses)
  end

  defp emit_neovim_statuses(state, status) do
    query =
      from r in ChannelReward,
        where: r.enabled_on == ^:neovim

    statuses =
      query
      |> Repo.all()
      |> Enum.reduce(state.statuses, fn reward, statuses ->
        Mixery.broadcast_event(%Event.RewardStatusUpdate{reward: reward, status: status})
        Map.put(statuses, reward.id, status)
      end)

    state |> Map.put(:statuses, statuses)
  end
end
