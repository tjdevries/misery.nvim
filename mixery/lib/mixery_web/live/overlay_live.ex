defmodule MixeryWeb.OverlayLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Media.Playerctl

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_play_media_events()
      Mixery.subscribe_to_execute_effect_events()
    end

    socket =
      socket
      |> assign(:themesongs, :queue.new())
      |> assign(:video_url, nil)
      |> assign(:effect, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <div :if={@effect}>
    #   <div class="bg-red-300 w-full h-full absolute"></div>
    # </div>

    audio_message =
      case :queue.out(assigns.themesongs) do
        {{:value, audio_message}, _} -> audio_message
        _ -> nil
      end

    case assigns.video_url do
      _ when audio_message != nil ->
        dbg({:audio_message, audio_message})

        ~H"""
        <div class="text-xl">
          <%= audio_message.greeting %> | <%= audio_message.user.display %>
          <audio autoplay src={audio_message.url} id="audio-player" phx-hook="AudioPlayer"></audio>
        </div>
        """

      url when url in [nil, ""] ->
        ~H"""
        No Audio
        """

      url ->
        ~H"""
        <div
          class={["flex mx-auto my-auto justify-center items-center rounded-lg min-h-screen"]}
          style="transform: scale(2);"
        >
          <video src={url} autoplay="true" />
        </div>
        """
    end
  end

  @impl true
  def handle_info(%Event.PlayAudio{audio_url: audio_url} = msg, socket) do
    Mixery.Media.Playerctl.pause()

    {:noreply,
     update(
       socket,
       :themesongs,
       &:queue.in(%{url: audio_url, user: msg.user, greeting: msg.greeting}, &1)
     )}
  end

  @impl true
  def handle_info(%Event.PlayVideo{video_url: video_url, length_ms: length}, socket) do
    status = Playerctl.status()

    case status do
      :playing -> Playerctl.pause()
      _ -> nil
    end

    Process.send_after(self(), {:remove_video, status}, length)
    {:noreply, assign(socket, :video_url, video_url)}
  end

  def handle_info(%Event.ExecuteEffect{effect: effect}, socket) do
    Process.send_after(self(), :remove_effect, 5000)
    {:noreply, assign(socket, :effect, effect)}
  end

  def handle_info(:remove_effect, socket) do
    {:noreply, assign(socket, :effect, nil)}
  end

  @impl true
  def handle_info({:remove_video, status}, socket) do
    case status do
      :playing -> Playerctl.play()
      _ -> nil
    end

    {:noreply, assign(socket, :video_url, nil)}
  end

  @impl true
  def handle_event("audio-ended", _, socket) do
    if :queue.len(socket.assigns.themesongs) == 1,
      do: Mixery.Media.Playerctl.play()

    {:noreply, update(socket, :themesongs, &:queue.drop/1)}
  end

  def handle_event(event, _, socket) do
    dbg({:unhandled_event, event})
    {:noreply, socket}
  end
end
