defmodule MixeryWeb.DashboardLive do
  use MixeryWeb, :live_view

  # alias Mixery.Event
  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.RewardHandler
  alias Mixery.Twitch.User
  alias Mixery.Twitch.ChannelReward

  # Components
  alias MixeryWeb.RewardComponent

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
      |> Enum.map(fn {_, {enabled, reward}} ->
        %{enabled: enabled, reward: reward}
      end)
      |> Enum.to_list()
      |> Enum.sort_by(& &1.reward.coin_cost)

    socket =
      socket
      |> assign(user: user)
      |> assign(display: user.display)
      |> assign(balance: balance)
      |> assign(gross: gross)
      |> assign(rewards: rewards)

    # |> assign(rewards: rewards)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 text-sm w-full">
      <div class="text-center text-4xl"><%= @user.display %></div>
      <div class="text-center">Twitch ID: <%= @user.id %></div>
      <div class="text-center flex justify-center gap-4">
        <div class="py-2 px-4 rounded-md border-2 border-orange-500">Balance: <%= @balance %></div>
        <div class="py-2 px-4 rounded-md border-2 border-orange-500">Accumulated: <%= @gross %></div>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-4 container mx-auto">
        <RewardComponent.card
          :for={%{enabled: enabled, reward: reward} <- @rewards}
          :if={enabled and reward.coin_cost > 0}
          balance={@balance}
          reward={reward}
        />
      </div>
    </div>
    """

    # <div class="grid grid-cols-2 gap-2 p-2">
    #   <div class="text-left">
    #     <h1 class="p-2 font-family-comic-sans"><%= @display %></h1>
    #     <p>Twitch ID: <%= @current_twitch %></p>
    #     <p>Current Teej Coins: <%= @balance %></p>
    #     <p>Gross Teej Coins: <%= @gross %></p>
    #   </div>
    #   <div class="flex flex-wrap gap-2">
    #     <div
    #       :for={%{enabled: enabled, reward: reward} <- @rewards}
    #       :if={enabled and reward.coin_cost > 0}
    #       class="min-w-full"
    #     >
    #       <RewardComponent.button balance={@balance} reward={reward} />
    #     </div>
    #   </div>
    # </div>
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
