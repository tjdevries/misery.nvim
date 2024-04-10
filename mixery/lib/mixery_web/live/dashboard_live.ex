defmodule MixeryWeb.DashboardLive do
  use MixeryWeb, :live_view

  # alias Mixery.Event
  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.RewardHandler
  alias Mixery.Twitch.User
  alias Mixery.Twitch.ChannelReward

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_coin_events()
      Mixery.subscribe_to_reward_status_update_events()
    end

    twitch_id = socket.assigns.current_twitch
    user = Repo.get!(User, twitch_id)

    balance =
      case Coin.balance(user).amount do
        nil -> 0
        amount -> amount
      end

    gross =
      case Coin.gross(user).amount do
        nil -> 0
        amount -> amount
      end

    # _ = Repo.all(ChannelReward)

    rewards =
      RewardHandler.get_all_reward_statuses()
      |> Enum.map(fn {id, {enabled, reward}} ->
        %{id: id, enabled: enabled, reward: reward}
      end)

    socket =
      socket
      |> assign(user: user)
      |> assign(display: user.display)
      |> assign(balance: balance)
      |> assign(gross: gross)
      |> stream(:rewards, rewards, reset: true)

    # |> assign(rewards: rewards)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center">
      <p><%= @display %></p>
      <p>Twitch ID: <%= @current_twitch %></p>
      <p>Current Teej Coins: <%= @balance %></p>
      <p>Gross Teej Coins: <%= @gross %></p>
      <div>
        <p class="text-4xl">You can afford this :)</p>
        <div id="reward-list" phx-update="stream">
          <div
            :for={{dom_id, %{id: reward_id, enabled: enabled, reward: reward}} <- @streams.rewards}
            id={dom_id}
          >
            <div :if={enabled and reward.coin_cost <= @balance and reward.coin_cost != 0}>
              <div phx-click="redeem" phx-value-reward-id={reward_id} class="text-center">
                <.button>
                  <%= reward_id %>: <%= reward.key %>. Costs: <%= reward.coin_cost %> coins
                </.button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div>
        <p class="text-4xl">YOU CAN_T AFFORD THIS</p>
        <div id="cant-afford-list" phx-update="stream">
          <div :for={{dom_id, %{id: reward_id, enabled: enabled, reward: reward}} <- @streams.rewards}>
            <div :if={enabled and reward.coin_cost > @balance and reward.coin_cost != 0}>
              <%= reward_id %>: <%= reward.key %>. Costs: <%= reward.coin_cost %> coins
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(
        %Event.Coin{user: %{id: twitch_id}, amount: amount, gross: gross},
        %{assigns: %{current_twitch: twitch_id}} = socket
      ) do
    {:noreply, socket |> assign(:balance, amount) |> assign(gross: gross)}
  end

  @impl true
  def handle_info(
        %Event.RewardStatusUpdate{status: status, reward: reward},
        socket
      ) do
    {:noreply,
     socket
     |> stream_insert(:rewards, %{id: reward.id, enabled: status, reward: reward})}
  end

  @impl true
  def handle_info(_info, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("redeem", %{"reward-id" => reward_id}, socket) do
    # Mixery.broadcast_event(%Event.Reward{})
    dbg({:clicked, reward_id})

    user = socket.assigns.user
    reward = Repo.get!(ChannelReward, reward_id)

    Mixery.Redemption.handle_redemption(user, reward)

    {:noreply, socket}
  end

  @impl true
  def handle_event(_, _, socket) do
    {:noreply, socket}
  end
end
