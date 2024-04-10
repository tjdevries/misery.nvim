defmodule MixeryWeb.LeaderboardLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Coin

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_coin_events()
    end

    gross = Coin.gross_all() |> Map.new(fn coin -> {coin.user.id, coin.amount} end)

    all_coins =
      Coin.balance_all()
      |> Enum.map(fn coin ->
        display =
          case coin.user.display do
            "" -> coin.user.login
            nil -> coin.user.login
            display -> display
          end

        %WebCoin{
          id: coin.user.id,
          display: display,
          amount: coin.amount,
          gross: gross[coin.user.id]
        }
      end)

    socket =
      socket
      |> stream(:coins, all_coins, reset: true)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="coins" style="display:grid" phx-update="stream" class="w-full bg-gray-900 px-4">
      <div :for={{dom_id, coin} <- @streams.coins} id={dom_id} style={"order:#{-coin.amount}"}>
        <%= coin.display %> <%= coin.amount %>
        <%= if coin.gross do %>
          (total: <%= coin.gross %>)
        <% end %>
      </div>
    </div>
    """
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
  def handle_info(%Event.Coin{user: user, amount: amount, gross: gross}, socket) do
    {:noreply,
     stream_insert(socket, :coins, %WebCoin{
       id: user.id,
       display: user.display,
       amount: amount,
       gross: gross
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
