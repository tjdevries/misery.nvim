defmodule MixeryWeb.OverlayLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Media.Playerctl

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_chat_events()
      Mixery.subscribe_to_notification_events()
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
      |> assign(:chat_messages, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    case assigns.current_notification do
      notification when notification in [nil, ""] ->
        ~H"""
        <!-- AIM Chat Container -->
        <div class="w-full max-w-md rounded-md shadow-lg font-sans text-lg">
          <!-- Header -->
          <!-- <div class="bg-gray-300 p-2 flex items-center">
            <div class="bg-yellow-500 h-3 w-3 rounded-full mr-2"></div>
            <span class="font-bold">Instant Message</span>
          </div> -->
          <!-- Chat Messages -->
          <div class="p-4 flex flex-col-reverse">
            <div :for={chat <- @chat_messages} class="mb-2">
              <div class="flex items-start overflow-hidden">
                <div class="bg-gray-100 text-black break-words p-2 rounded-md w-full">
                  <div class="flex flex-row gap-4 items-center">
                    <img src={chat.user.profile_image_url} class="h-10 w-10 rounded-full" />
                    <span class="text-blue-700 font-bold"><%= chat.user.display %></span>
                  </div>
                  <%= chat.message.text %>
                </div>
              </div>
            </div>
          </div>
        </div>
        """

      notification when notification in [nil, ""] ->
        ~H"""
        <.screenkey key={@key} neovim_connected={@neovim_connected} />
        <div class="bg-gray-100 w-xl max-w-xl">
          <div :for={chat <- @chat_messages} class="space-y-4">
            <div class="flex items-start space-x-3">
              <!-- User Avatar -->
              <div class="flex-shrink-0">
                <img
                  class="h-10 w-10 rounded-full"
                  src={chat.user.profile_image_url}
                  alt={chat.user.display}
                />
              </div>
              <div>
                <div class="text-sm font-bold text-indigo-600">
                  <%= chat.user.display %>
                </div>
                <div class="mt-1">
                  <span class="inline-block bg-indigo-100 text-indigo-800 text-sm p-2 rounded-lg">
                    <%= chat.message.text %>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
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

      %{kind: :audio} ->
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

      %{kind: :self_subscriber} ->
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
              <div class="flex flex-col items-center text-center justify-center">
                <div class="text-white text-3xl text-center font-semibold">
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

      %{kind: :gift_subscription} ->
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
              <div class="flex flex-col text-center items-center justify-center">
                <div class="text-white text-center text-3xl font-semibold">
                  <%= @current_notification.user.display %> Just Gifted <%= @current_notification.data.total %> Subscriptions
                </div>

                <div class="text-white text-xl font-semibold">
                  <%= @current_notification.data.message %>
                </div>
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
    dbg({:overlay, "effect", effect})

    # [(mix
    # {:overlay, "effect", effect} #=> {:overlay, "effect",
    #  %Mixery.Effect{
    #    __meta__: #Ecto.Schema.Metadata<:loaded, "effects">,
    #    id: "random-colorscheme",
    #    title: "Random colorscheme",
    #    prompt: "Will pick a random colorscheme.",
    #    cost: 1,
    #    is_user_input_required: false,
    #    enabled_on: :neovim,
    #    cooldown: nil,
    #    max_per_stream: nil,
    #    max_per_user_per_stream: nil,
    #    inserted_at: ~U[2024-07-29 18:53:37Z],
    #    up
    #  }}
    case effect.id do
      "jumpscare" ->
        nil

      _ ->
        nil
    end

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

  def handle_info(%Event.Chat{} = message, socket) do
    dbg({:chat, socket.assigns.chat_messages})

    {:noreply,
     update(socket, :chat_messages, fn notifications ->
       [message | notifications || []] |> Enum.take(10)
     end)}
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
