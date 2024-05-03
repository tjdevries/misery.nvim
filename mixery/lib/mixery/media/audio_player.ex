defmodule Mixery.Media.AudioPlayer do
  use GenServer

  # alias Mixery.Event
  alias Mixery.Media.Playerctl

  @impl GenServer
  def init(_) do
    # Mixery.subscribe_to_play_media_events()
    {:ok, %{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # def handle_info(%Event.PlayAudio{audio_url: url}, state) do
  #   GenServer.cast(__MODULE__, {:play_song, url})
  #   {:noreply, state}
  # end

  def add_to_queue(path) do
    GenServer.cast(__MODULE__, {:play_song, path})
  end

  @impl GenServer
  def handle_cast({:play_song, path}, state) do
    status = Playerctl.status()

    # Pause the music, if it was playing
    if status == :playing, do: Playerctl.pause()

    System.cmd("mpv", ["--no-terminal", path])

    # Resume the music, if it was playing
    if status == :playing, do: Playerctl.play()

    # Comments added for less-than-the-brightest-twitch-chat-reviewers KEKL

    {:noreply, state}
  end
end
