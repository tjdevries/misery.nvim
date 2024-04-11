defmodule MixeryWeb.LeaderboardLive do
  use MixeryWeb, :live_view

  alias Mixery.Event
  alias Mixery.Coin

  defmodule WebCoin do
    defstruct [:id, :display, :amount, :gross]
  end

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
  def handle_info(%Event.Coin{user: user, amount: amount, gross: gross}, socket) do
    {:noreply,
     stream_insert(socket, :coins, %WebCoin{
       id: user.id,
       display: user.display,
       amount: amount,
       gross: gross
     })}
  end
end
