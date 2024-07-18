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
  def handle_info(%Subscription{} = sub, state) do
    # notification = Event.Notification.video("/media/tier1.mp4", "")
    notification =
      Event.Notification.subscriber(
        user: sub.subscription.user,
        url: "/media/tier1.mp4",
        sub_tier: :tier_1,
        cumulative: 4,
        duration: 4,
        streak: 4,
        message: "Hello world!"
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
