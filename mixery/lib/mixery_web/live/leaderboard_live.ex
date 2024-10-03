defmodule MixeryWeb.LeaderboardLive do
  use MixeryWeb, :live_view

  use TypedStruct

  alias Mixery.Event
  alias Mixery.Coin

  defmodule WebCoin do
    typedstruct enforce: true do
      field :id, String.t()
      field :profile_image_url, String.t()
      field :display, String.t()
      field :amount, pos_integer()
      field :gross, pos_integer()
    end
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
          profile_image_url: coin.user.profile_image_url,
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
    <div id="coins" phx-update="stream" class="grid grid-cols-3 w-full bg-gray-900 px-4">
      <div :for={{dom_id, coin} <- @streams.coins} id={dom_id} style={"order:#{-coin.amount}"}>
        <div class="border border-white text-center rounded-lg p-4 m-4">
          <div>
            <%= if coin.profile_image_url do %>
              <img src={coin.profile_image_url} class="w-16 h-16 rounded-full" />
            <% end %>
            <div class="text-center">
              <%= coin.display %>
            </div>
          </div>
          <div class="text-sm">
            <%= coin.amount %>
            <%= if coin.gross do %>
              (total: <%= coin.gross %>)
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(%Event.Coin{user: user, amount: amount, gross: gross}, socket) do
    {:noreply,
     stream_insert(socket, :coins, %WebCoin{
       id: user.id,
       profile_image_url: user.profile_image_url,
       display: user.display,
       amount: amount,
       gross: gross
     })}
  end
end
