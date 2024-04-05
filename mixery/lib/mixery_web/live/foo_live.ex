defmodule WebCoin do
  defstruct [:id, :display, :amount, :gross]
end

defmodule MixeryWeb.FooLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Coin

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_chat_events()
      Mixery.subscribe_to_coin_events()
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
      |> assign(redemptions: [])
      |> assign(chats: [])
      |> assign(all_chats: [])
      |> assign(:form, to_form(%{"user" => nil}))
      |> stream(:coins, all_coins, reset: true)
      |> assign(:coin_map, Map.new(all_coins, &{&1.id, &1.amount}))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <h1>Redemptions</h1>
    # <div :for={redemption <- @redemptions}>
    #   <%= redemption.user_login %>: <%= redemption.reward_title %>
    #   <span :if={redemption.user_input != ""}>
    #     (<%= redemption.user_input %>)
    #   </span>
    # </div>

    # <.form for={@form} phx-change="chat-filter">
    #   <.input type="text" field={@form[:user]} />
    # </.form>

    # <div id="coins" style="display:grid" phx-update="stream" phx-hook class="w-full">
    #   <div :for={{dom_id, coin} <- @streams.coins} id={dom_id} style={"order:#{-coin.amount}"}>
    #     <%= coin.display %> <%= coin.amount %>
    #   </div>
    # </div>

    ~H"""
    <div class="w-full h-full">
      <div class="text-white w-full flex flex-col text-right justify-right">
        <div :for={chat <- @chats}>
          <div>
            <%= chat.user.login %>(<%= @coin_map[chat.user.id] %>): <%= chat.message %>
          </div>
        </div>
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
