defmodule MixeryWeb.OverlayLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Media.Playerctl

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_play_video_events()
      Mixery.subscribe_to_execute_effect_events()
    end

    socket =
      socket
      |> assign(:video_url, nil)
      |> assign(:effect, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    case assigns.video_url do
      url when url in [nil, ""] ->
        ~H"""
        <div :if={@effect}>
          <div class="bg-red-300 w-full h-full absolute"></div>
        </div>
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
end
