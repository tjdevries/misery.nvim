defmodule MixeryWeb.OverlayLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Coin
  alias Mixery.Media.Playerctl

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_coin_events()
      Mixery.subscribe_to_play_video_events()
    end

    all_coins =
      Coin.balance_all()
      |> Enum.map(fn coin ->
        display =
          case coin.user.display do
            "" -> coin.user.login
            nil -> coin.user.login
            display -> display
          end

        %WebCoin{id: coin.user.id, display: display, amount: coin.amount}
      end)

    socket =
      socket
      |> stream(:coins, all_coins, reset: true)
      |> assign(:video_url, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <div
    #   id="coins"
    #   style="display:grid"
    #   phx-update="stream"
    #   phx-hook
    #   class="w-full"
    #   style="background-color: transparent"
    # >
    #   <div :for={{dom_id, coin} <- @streams.coins} id={dom_id} style={"order:#{-coin.amount}"}>
    #     <%= coin.display %> <%= coin.amount %>
    #   </div>
    # </div>

    # <div class={["mx-auto w-full rounded-lg"]}>
    #   <video src={~p"/images/focused.webm"} autoplay="true" />
    # </div>

    case assigns.video_url do
      url when url in [nil, ""] ->
        ~H"""

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

  @impl true
  def handle_info({:remove_video, status}, socket) do
    case status do
      :playing -> Playerctl.play()
      _ -> nil
    end

    {:noreply, assign(socket, :video_url, nil)}
  end

  @impl true
  def handle_info(%Event.Chat{} = message, socket) do
    # socket =
    #   case message.message do
    #     "!addcoin " <> message ->
    #       split = String.split(message, ":")
    #
    #       case split do
    #         [user, amount] ->
    #           stream_insert(socket, :coins, %WebCoin{
    #             id: user,
    #             user: %{login: user},
    #             amount: amount
    #           })
    #
    #         _ ->
    #           socket
    #       end
    #
    #     _ ->
    #       socket
    #   end
    #
    {:noreply,
     update(socket, :all_chats, &[message | &1])
     |> assign_chats()}
  end

  @impl true
  def handle_info(%Event.Coin{user: user, amount: amount}, socket) do
    {:noreply,
     stream_insert(socket, :coins, %WebCoin{
       id: user.id,
       display: user.display,
       amount: amount
     })}
  end

  @impl true
  def handle_event("chat-filter", %{"user" => user}, socket) do
    # dbg({:event, socket})
    {:noreply, assign(socket, :form, to_form(%{"user" => user})) |> assign_chats()}
  end

  defp assign_chats(socket) do
    case socket.assigns.form.source["user"] do
      nil ->
        assign(socket, :chats, socket.assigns.all_chats)

      "" ->
        assign(socket, :chats, socket.assigns.all_chats)

      user ->
        assign(
          socket,
          :chats,
          Enum.filter(socket.assigns.all_chats, &match?(^user <> _, &1.user.login))
        )
    end
  end
end
