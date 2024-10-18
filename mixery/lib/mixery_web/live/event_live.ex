defmodule MixeryWeb.EventLive do
  use MixeryWeb, :live_view
  require Logger

  alias Mixery.Event
  alias Mixery.Event.Subscription
  # alias Mixery.Coin
  # alias Mixery.EffectStatusHandler
  # alias Mixery.Event
  # alias Mixery.Repo
  # alias Mixery.Twitch.User
  # alias Mixery.Effect
  # alias Mixery.Themesong

  # Components
  # alias MixeryWeb.EffectComponent

  alias MixeryWeb.CoreComponents

  @impl true
  def mount(_params, _session, socket) do
    themesongs = Mixery.Themesong.get()

    socket =
      socket
      |> assign(:themesongs_full, themesongs)
      |> assign(:themesongs_matched, themesongs)
      |> assign(:query, nil)

    {:ok, socket}
  end

  @impl true
  def render(%{user: nil} = assigns) do
    ~H"""
    Send a chat message or something, to make sure this is workin
    """
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 text-sm text-black w-full">
      <div>Hello World</div>

      <form phx-change="themesong-change" phx-submit="themesong-play">
        <input type="text" name="themesong-query" value={@query} list="themesong-list" />
        <datalist id="themesong-list">
          <%= for themesong <- @themesongs_matched do %>
            <option value={themesong.twitch_user_id}><%= themesong.name %></option>
          <% end %>
        </datalist>
      </form>

      <CoreComponents.button class="button" phx-click="subscriber-test">
        Test Subscription Event
      </CoreComponents.button>

      <CoreComponents.button class="button" phx-click="gift-test">
        Test Gifted Subscription Event
      </CoreComponents.button>
    </div>
    """
  end

  @impl true
  def handle_event("subscriber-test", _, socket) do
    user = Mixery.Twitch.get_user("114257969")

    Mixery.broadcast_event(
      Subscription.self_subscription(
        user,
        %Event.Subscription.ReSub{
          sub_tier: :tier_1,
          duration: 1,
          streak: 3,
          cumulative: 12
        }
      )
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("gift-test", _, socket) do
    user = Mixery.Twitch.get_user("1068066839")

    Mixery.broadcast_event(
      Subscription.gift_subscription(
        user,
        35,
        "YAYAYAYA"
      )
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("themesong-change", %{"themesong-query" => query}, socket) do
    {:noreply,
     assign(socket,
       themesongs_matched:
         socket.assigns.themesongs_full
         |> Enum.filter(fn themesong ->
           String.contains?(themesong.name, query) ||
             String.contains?(themesong.twitch_user_id, query)
         end)
     )}
  end

  @impl true
  def handle_event("themesong-play", %{"themesong-query" => query}, socket) do
    Logger.info("query: #{query}")

    case socket.assigns.themesongs_matched do
      [themesong] ->
        user = Mixery.Twitch.get_user(themesong.twitch_user_id)

        Mixery.broadcast_event(
          Event.Notification.themesong(
            "/themesongs/themesong-#{user.id}.mp3",
            themesong.name,
            user
          )
        )

      _ ->
        dbg({:themesongs_matched, socket.assigns.themesongs_matched})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:search, query}, socket) do
    {result, _} = System.cmd("dict", ["#{query}"], stderr_to_stdout: true)
    {:noreply, assign(socket, loading: false, result: result, matches: [])}
  end
end
