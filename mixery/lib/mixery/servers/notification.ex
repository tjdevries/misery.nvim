defmodule Mixery.Servers.Notification do
  use GenServer

  alias Mixery.Event

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    Mixery.subscribe_to_notification_events()
    Mixery.subscribe_to_notification_ended_events()

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
    {:noreply, :queue.in(event, state)}
  end

  @impl true
  def handle_info(%Event.Notification.Ended{event: event}, state) do
    {:noreply, :queue.filter(fn x -> x.id != event.id end, state)}
  end

  @impl true
  def handle_info(event, state) do
    Sentry.capture_message("Unhandled notification: #{inspect(event)}")
    {:noreply, state}
  end
end
