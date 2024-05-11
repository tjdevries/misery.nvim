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
      |> assign(:media, :queue.new())
      |> assign(:current_media, nil)
      |> assign(:effect, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <div :if={@effect}>
    #   <div class="bg-red-300 w-full h-full absolute"></div>
    # </div>
    case assigns.current_media do
      media when media in [nil, ""] ->
        ~H"""

        """

      %{kind: "themesong"} ->
        ~H"""
        <div
          id="yeah-toast"
          class="slide-in-right w-[600px] m-16 absolute right-10 text-gray-500 bg-white rounded-lg shadow dark:bg-gray-800 dark:text-gray-400"
          role="alert"
        >
          <audio
            autoplay
            src={@current_media.url}
            id={"audio-player-#{@current_media.id}"}
            phx-hook="MediaPlayer"
          >
          </audio>
          <div class="flex w-full">
            <img class="m-8 w-32 h-32 rounded-full" src={@current_media.user.profile_image_url} />
            <div class="m-8 text-2xl font-normal">
              <span class="mb-8 text-3xl font-semibold text-gray-900 dark:text-white">
                <%= @current_media.user.display %>
              </span>
              <div class="m-8 text-2xl font-normal">
                <%= @current_media.greeting %>
              </div>
            </div>
          </div>
        </div>
        """

      %{kind: "video"} ->
        ~H"""
        <div
          id="yeah-toast"
          class={["flex mx-auto my-auto justify-center items-center rounded-lg min-h-screen"]}
        >
          <video
            style="transform: scale(2);"
            src={@current_media.url}
            autoplay="true"
            id={"video-player-#{@current_media.id}"}
            phx-hook="MediaPlayer"
          />
        </div>
        """
    end
  end

  @impl true
  def handle_info(%Event.PlayAudio{audio_url: audio_url} = msg, socket) do
    Playerctl.pause()

    media = %{
      id: UUID.uuid4(),
      kind: "themesong",
      url: audio_url,
      user: msg.user,
      greeting: msg.greeting
    }

    case socket.assigns.current_media do
      nil -> {:noreply, socket |> assign(:current_media, media)}
      _ -> {:noreply, socket |> update(:media, &:queue.in(media, &1))}
    end
  end

  @impl true
  def handle_info(%Event.PlayVideo{video_url: video_url}, socket) do
    Playerctl.pause()

    media = %{
      id: UUID.uuid4(),
      kind: "video",
      url: video_url
    }

    case socket.assigns.current_media do
      nil -> {:noreply, socket |> assign(:current_media, media)}
      _ -> {:noreply, socket |> update(:media, &:queue.in(media, &1))}
    end
  end

  def handle_info(%Event.ExecuteEffect{effect: effect}, socket) do
    Process.send_after(self(), :remove_effect, 5000)
    {:noreply, assign(socket, :effect, effect)}
  end

  def handle_info(:remove_effect, socket) do
    {:noreply, assign(socket, :effect, nil)}
  end

  @impl true
  def handle_event("media-ended", _, socket) do
    # current_media = socket.assigns.current_media
    # JS.remove_class("slide-in-right", to: "#toast-#{current_media.id}")
    # JS.add_class("slide-out-top", to: "#toast-#{current_media.id}")

    {item, media} =
      case :queue.out(socket.assigns.media) do
        {:empty, media} ->
          Mixery.Media.Playerctl.play()
          {nil, media}

        {{:value, item}, media} ->
          {item, media}
      end

    {:noreply, socket |> assign(current_media: item, media: media)}
  end

  def handle_event(event, _, socket) do
    dbg({:unhandled_event, event})
    {:noreply, socket}
  end
end
