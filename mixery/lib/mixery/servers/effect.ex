defmodule Mixery.Servers.Effect do
  use GenServer

  alias Mixery.Event

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    Mixery.subscribe_to_execute_effect_events()

    {:ok, nil}
  end

  @impl true
  def handle_info(%Event.ExecuteEffect{effect: %{id: "jumpscare"}, user: user}, state) do
    # Pick a random sound from:
    sounds = [
      "/media/air-horn.mp3",
      "/media/charlie-scream.mp3",
      "/media/inception-horn.mp3",
      "/media/metal-pipe.mp3",
      "/media/stop.mp3"
    ]

    sound = Enum.random(sounds)

    Mixery.broadcast_event(Mixery.Event.Notification.audio(sound, "JUMPSCARE TIME", user))
    {:noreply, state}
  end

  def handle_info(%Event.ExecuteEffect{} = event, state) do
    dbg({:new_event, event.id})
    {:noreply, state}
  end
end
