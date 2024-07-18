defmodule MixeryWeb.OverlayLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Media.Playerctl

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_notifications()
      Mixery.subscribe_to_neovim_events()
      Mixery.subscribe_to_neovim_connection_events()
    end

    notifications = Mixery.Servers.Notification.status()
    dbg({:overlay, "loading", debug_notifications(notifications)})

    current =
      case :queue.peek(notifications) do
        {:value, current} -> current
        _ -> nil
      end

    socket =
      socket
      |> assign(:notifications, notifications)
      |> assign(:current_notification, current)
      |> assign(:effect, nil)
      |> assign(:key, nil)
      |> assign(:neovim_connected, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <div :if={@effect}>
    #   <div class="bg-red-300 w-full h-full absolute"></div>
    # </div>
    case assigns.current_notification do
      notification when notification in [nil, ""] ->
        ~H"""
        <.screenkey key={@key} neovim_connected={@neovim_connected} />
        """

      %{kind: :themesong} ->
        ~H"""
        <div
          id="yeah-toast"
          class="slide-in-right w-[600px] m-16 absolute right-10 text-gray-500 bg-white rounded-lg shadow dark:bg-gray-800 dark:text-gray-400"
          role="alert"
        >
          <audio
            autoplay
            src={@current_notification.data.url}
            id={"audio-player-#{@current_notification.id}"}
            phx-hook="MediaPlayer"
          >
          </audio>
          <div class="flex w-full">
            <img class="m-8 w-32 h-32 rounded-full" src={@current_notification.user.profile_image_url} />
            <div class="m-8 text-2xl font-normal">
              <span class="mb-8 text-3xl font-semibold text-gray-900 dark:text-white">
                <%= @current_notification.user.display %>
              </span>
              <div class="m-8 text-2xl font-normal">
                <%= @current_notification.data.message %>
              </div>
            </div>
          </div>
        </div>
        """

      %{kind: :video} ->
        ~H"""
        <div
          id="yeah-toast"
          class={["flex mx-auto my-auto justify-center items-center rounded-lg min-h-screen"]}
        >
          <video
            style={@current_notification.data.style}
            src={@current_notification.data.url}
            autoplay="true"
            id={"video-player-#{@current_notification.id}"}
            phx-hook="MediaPlayer"
          />
        </div>
        """

      %{kind: :subscriber} ->
        # "flex mx-auto my-auto justify-center items-center rounded-lg min-h-screen slide-in-right"
        ~H"""
        <div
          id="yeah-toast"
          class={[
            "slide-in-right w-[900px] m-16 absolute right-10 text-gray-500 bg-white rounded-lg shadow",
            "dark:bg-gray-800 dark:text-gray-400"
          ]}
        >
          <div class="relative">
            <video
              class=""
              style=""
              src={@current_notification.data.url}
              autoplay="true"
              id={"video-player-#{@current_notification.id}"}
              phx-hook="MediaPlayer"
            />
            <div
              style={[
                "filter: blur(4px);"
              ]}
              class={[
                "animate-pulse",
                "rounded-3xl",
                "backdrop-blur-xl",
                "absolute bg-black/25 right-[5%] top-[5%]",
                "w-[60%] h-[40%]"
              ]}
            >
            </div>
            <div class={[
              "absolute bg-black right-[10%] top-[10%]",
              "w-1/2 h-[30%]"
            ]}>
              <div class="flex flex-col items-center justify-center">
                <div class="text-white text-3xl font-semibold">
                  <%= @current_notification.user.display %> Just Subscribed
                </div>

                <div class="text-white text-xl font-semibold">
                  <%= @current_notification.data.message %>
                </div>

                <%= if @current_notification.data.cumulative > 0 do %>
                  <div class="text-white text-xl font-semibold">
                    <%= @current_notification.data.cumulative %> Months Subscribed!
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        """

      %{kind: :text} ->
        ~H"""
        <div
          id="yeah-toast"
          class={["flex mx-auto my-auto justify-center items-center rounded-lg min-h-screen"]}
        >
          <div
            id={"text-player-#{@current_notification.id}"}
            class="flex w-full"
            phx-hook="TextPlayer"
            data-timeout={2000}
          >
            <div class="m-8 text-2xl font-normal">
              <div class="m-8 text-2xl font-normal">
                <%= @current_notification.data.message %>
              </div>
            </div>
          </div>
        </div>
        """
    end
  end

  @impl true
  def handle_info(%Event.Notification{} = msg, socket) do
    # Note: This might not be the best place to pause the music,
    # maybe there's a spot in the render section or some other update hook we could do.
    Playerctl.pause()

    socket =
      case socket.assigns.current_notification do
        nil -> socket |> assign(:current_notification, msg)
        _ -> socket |> update(:notifications, &:queue.in(msg, &1))
      end

    dbg({:overlay, "notifications", debug_notifications(socket.assigns.notifications)})

    {:noreply, socket}
  end

  def handle_info(%Event.ExecuteEffect{effect: effect}, socket) do
    Process.send_after(self(), :remove_effect, 5000)
    {:noreply, assign(socket, :effect, effect)}
  end

  def handle_info(%Event.NeovimConnection{connections: []}, state) do
    {:noreply, assign(state, :neovim_connected, false)}
  end

  def handle_info(%Event.NeovimConnection{}, state) do
    {:noreply, assign(state, :neovim_connected, true)}
  end

  def handle_info(%Event.NeovimOnKey{key: key}, socket) do
    {:noreply, assign(socket, :key, key)}
  end

  def handle_info(:remove_effect, socket) do
    {:noreply, assign(socket, :effect, nil)}
  end

  @impl true
  def handle_event("notification-ended", _, socket) do
    # current_notification = socket.assigns.current_notification
    # JS.remove_class("slide-in-right", to: "#toast-#{current_notification.id}")
    # JS.add_class("slide-out-top", to: "#toast-#{current_notification.id}")

    Mixery.broadcast_event(%Event.Notification.Ended{event: socket.assigns.current_notification})

    {item, notification} =
      case :queue.out(socket.assigns.notifications) do
        {:empty, notification} ->
          Mixery.Media.Playerctl.play()
          {nil, notification}

        {{:value, item}, notification} ->
          {item, notification}
      end

    {:noreply, socket |> assign(current_notification: item, notifications: notification)}
  end

  def handle_event(event, _, socket) do
    dbg({:unhandled_event, event})
    {:noreply, socket}
  end

  defp screenkey(assigns) do
    case {assigns.neovim_connected, assigns.key} do
      {false, _} ->
        ~H"""

        """

      {_, nil} ->
        ~H"""

        """

      _ ->
        ~H"""
        <div style="position: absolute; bottom: 0; left: 40%;">
          Current Key: <%= @key %>
        </div>
        """
    end
  end

  defp debug_notifications(notifications) do
    :queue.filtermap(fn item -> {true, item.id} end, notifications)
  end
end
