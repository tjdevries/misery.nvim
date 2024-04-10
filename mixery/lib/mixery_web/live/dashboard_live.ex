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
   <div class="app">
    <div class="app-content">
        <h1 class=""><%= @title %></h1>
        <p>Twitch ID: <%= @twitchId %></p>
        <div class="teej-coins">
            <button disabled><%= @currentTeejCoins %></button>
            <button disabled><%= @grossTeejCoins %></button>
        </div>
        <a href="<%= @twitchLink %>" class="btn"><%= @getPointsText %></a>

        <ul class="rewards">
            <% @rewards.forEach(function(reward) { %>
                <li>
                    <div class="badge elite">
                        <svg stroke="currentColor" fill="currentColor" stroke-width="0" viewBox="0 0 496 512"
                            height="33px" width="33px" xmlns="http://www.w3.org/2000/svg">
                            <path
                                d="M248 8C111 8 0 119 0 256s111 248 248 248 248-111 248-248S385 8 248 8zm144 386.4V280c0-13.2-10.8-24-24-24s-24 10.8-24 24v151.4C315.5 447 282.8 456 248 456s-67.5-9-96-24.6V280c0-13.2-10.8-24-24-24s-24 10.8-24 24v114.4c-34.6-36-56-84.7-56-138.4 0-110.3 89.7-200 200-200s200 89.7 200 200c0 53.7-21.4 102.5-56 138.4zM205.8 234.5c4.4-2.4 6.9-7.4 6.1-12.4-4-25.2-34.2-42.1-59.8-42.1s-55.9 16.9-59.8 42.1c-.8 5 1.7 10 6.1 12.4 4.4 2.4 9.9 1.8 13.7-1.6l9.5-8.5c14.8-13.2 46.2-13.2 61 0l9.5 8.5c2.5 2.3 7.9 4.8 13.7 1.6zM344 180c-25.7 0-55.9 16.9-59.8 42.1-.8 5 1.7 10 6.1 12.4 4.5 2.4 9.9 1.8 13.7-1.6l9.5-8.5c14.8-13.2 46.2-13.2 61 0l9.5 8.5c2.5 2.2 8 4.7 13.7 1.6 4.4-2.4 6.9-7.4 6.1-12.4-3.9-25.2-34.1-42.1-59.8-42.1zm-96 92c-30.9 0-56 28.7-56 64s25.1 64 56 64 56-28.7 56-64-25.1-64-56-64z">
                            </path>
                        </svg>

                        <h2><%= reward.title %></h2>
                    </div>
                    <div class="reward-content">
                        <p><%= reward.description %></p>

                        <div>
                            <button type="button" class="btn">
                                <svg stroke="currentColor" fill="currentColor" stroke-width="0" viewBox="0 0 24 24"
                                    height="20px" width="20px" xmlns="http://www.w3.org/2000/svg">
                                    <path d="M12.0049 22.0029C6.48204 22.0029 2.00488 17.5258
                                    2.00488 12.0029C2.00488 6.48008 6.48204 2.00293 12.0049
                                    2.00293C17.5277 2.00293 22.0049 6.48008 22.0049
                                    12.0029C22.0049 17.5258 17.5277 22.0029 12.0049
                                    22.0029ZM12.0049 7.76029L7.76224 12.0029L12.0049
                                    16.2456L16.2475 12.0029L12.0049 7.76029Z"></path>
                                </svg>
                                <span><%= reward.points %></span>
                            </button>

                            <button type="button" class="btn">Redeem</button>
                        </div>
                    </div>
                </li>
            <% }); %>
        </ul>
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
