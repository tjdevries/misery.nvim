defmodule Mixery.Servers.Subscriptions do
  use GenServer

  alias Mixery.Event
  alias Mixery.Event.Subscription

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    Mixery.subscribe_to_sub_events()

    {:ok, nil}
  end

  @impl true
  def handle_info(%Subscription{subscription: %Subscription.SelfSubscription{}} = sub, state) do
    self_sub = sub.subscription.subscription

    cumulative = Map.get(self_sub, :cumulative, 0)
    duration = Map.get(self_sub, :duration, 0)
    streak = Map.get(self_sub, :streak, 0)

    Mixery.broadcast_event(
      Event.Notification.self_subscriber(
        user: sub.subscription.user,
        url: "/media/tier1.mp4",
        sub_tier: self_sub.sub_tier,
        cumulative: cumulative,
        duration: duration,
        streak: streak,
        message: sub.message
      )
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(
        %Subscription{
          subscription: %Subscription.GiftSubscription{
            subscription: %Subscription.CommunitySubGift{}
          }
        } = sub,
        state
      ) do
    url =
      case sub.subscription.subscription.total do
        total when total >= 50 -> "/media/gifted-50.mp4"
        total when total >= 20 -> "/media/gifted-20.mp4"
        _ -> "/media/tier1.mp4"
      end

    Mixery.broadcast_event(
      Event.Notification.gift_subscription(
        user: sub.subscription.gifter,
        url: url,
        total: sub.subscription.subscription.total,
        sub_tier: sub.subscription.subscription.sub_tier,
        message: sub.message
      )
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(event, state) do
    Sentry.capture_message("Unhandled subscription message: #{inspect(event)}")
    {:noreply, state}
  end
end
