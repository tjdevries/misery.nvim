defmodule Mixery.Servers.Notification do
  use GenServer

  alias Mixery.Event
  alias Mixery.Event.Subscription

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    Mixery.subscribe_to_sub_events()
    Mixery.subscribe_to_notifications()
    Mixery.subscribe_to_notification_ended()

    {:ok, :queue.new()}
  end

  @spec status() :: :queue.queue()
  def status() do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(%Event.Notification{} = event, state) do
    dbg({:new_event, event.id})
    {:noreply, :queue.in(event, state)}
  end

  @impl true
  def handle_info(%Event.Notification.Ended{event: event}, state) do
    dbg({:ended_event, event.id})
    {:noreply, :queue.filter(fn x -> x.id != event.id end, state)}
  end

  @impl true
  def handle_info(%Subscription{subscription: %Subscription.SelfSubscription{}} = sub, state) do
    self_sub = sub.subscription.subscription

    cumulative = Map.get(self_sub, :cumulative, 0)
    duration = Map.get(self_sub, :duration, 0)
    streak = Map.get(self_sub, :streak, 0)

    notification =
      Event.Notification.self_subscriber(
        user: sub.subscription.user,
        url: "/media/tier1.mp4",
        sub_tier: self_sub.sub_tier,
        cumulative: cumulative,
        duration: duration,
        streak: streak,
        message: sub.message
      )

    Mixery.broadcast_event(notification)

    {:noreply, :queue.in(notification, state)}
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

    notification =
      Event.Notification.gift_subscription(
        user: sub.subscription.gifter,
        url: url,
        total: sub.subscription.subscription.total,
        sub_tier: sub.subscription.subscription.sub_tier,
        message: sub.message
      )

    Mixery.broadcast_event(notification)

    {:noreply, :queue.in(notification, state)}
  end

  @impl true
  def handle_info(event, state) do
    dbg({:unhandled, event})
    {:noreply, state}
  end
end
