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
    end

    twitch_id = socket.assigns.current_twitch
    user = Repo.get!(User, twitch_id)

    balance =
      case Coin.balance(user) do
        nil -> 0
        balance -> balance.amount
      end

    gross =
      case Coin.gross(user) do
        nil -> 0
        gross -> gross.amount
      end

    # _ = Repo.all(ChannelReward)

    reward_statuses = RewardHandler.get_all_reward_statuses()

    socket =
      socket
      |> assign(display: user.display)
      |> assign(balance: balance)
      |> assign(gross: gross)
      |> assign(reward_statuses: reward_statuses)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center">
      <p><%= @display %></p>
      <p>HI SLAMMY</p>
      <p>Twitch ID: <%= @current_twitch %></p>
      <p>Current Teej Coins: <%= @balance %></p>
      <p>Gross Teej Coins: <%= @gross %></p>
      <div :for={{reward_id, reward_status} <- @reward_statuses}>
        <p><%= reward_id %>: <%= reward_status %></p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(
        %Event.Coin{user: %{id: twitch_id}, amount: amount},
        %{assigns: %{current_twitch: twitch_id}} = socket
      ) do
    {:noreply, assign(socket, :balance, amount)}
  end

  @impl true
  def handle_info(_info, socket) do
    {:noreply, socket}
  end
end
