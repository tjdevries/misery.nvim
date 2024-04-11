defmodule MixeryWeb.DashboardLive do
  use MixeryWeb, :live_view

  # alias Mixery.Event
  alias Mixery.Coin
  alias Mixery.EffectStatusHandler
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch.User
  alias Mixery.Effect

  # Components
  alias MixeryWeb.EffectComponent

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Mixery.subscribe_to_coin_events()
      Mixery.subscribe_to_effect_status_update_events()
    end

    twitch_id = socket.assigns.current_twitch
    user = Repo.get!(User, twitch_id)

    balance =
      case Coin.balance(user).amount do
        nil -> 0
        amount -> amount
      end

    gross =
      case Coin.gross(user).amount do
        nil -> 0
        amount -> amount
      end

    effects =
      EffectStatusHandler.get_all_effect_statuses()
      |> Enum.map(fn {enabled, effect} ->
        %{enabled: enabled == :enabled, effect: effect}
      end)
      |> Enum.to_list()
      |> Enum.sort_by(& &1.effect.cost)

    socket =
      socket
      |> assign(user: user)
      |> assign(display: user.display)
      |> assign(balance: balance)
      |> assign(gross: gross)
      |> assign(effects: effects)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 text-sm w-full">
      <div class="text-center text-4xl"><%= @user.display %></div>
      <div class="text-center">Twitch ID: <%= @user.id %></div>
      <div class="text-center flex justify-center gap-4">
        <div class="py-2 px-4 rounded-md border-2 border-orange-500">Balance: <%= @balance %></div>
        <div class="py-2 px-4 rounded-md border-2 border-orange-500">Accumulated: <%= @gross %></div>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-4 container mx-auto">
        <EffectComponent.card
          :for={%{enabled: enabled, effect: effect} <- @effects}
          :if={enabled and effect.cost > 0}
          balance={@balance}
          effect={effect}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(
        %Event.Coin{user: %{id: twitch_id}, amount: amount, gross: gross},
        %{assigns: %{current_twitch: twitch_id}} = socket
      ) do
    {:noreply, socket |> assign(:balance, amount) |> assign(gross: gross)}
  end

  @impl true
  def handle_info(
        %Event.EffectStatusUpdate{status: status, effect: effect},
        socket
      ) do
    index =
      Enum.find_index(socket.assigns.effects, fn %{effect: e} -> e.id == effect.id end)

    socket =
      assign(
        socket,
        :effects,
        socket.assigns.effects
        |> List.replace_at(
          index,
          Enum.at(socket.assigns.effects, index) |> Map.put(:enabled, status)
        )
      )

    # item.enabled = status
    # socket = assign(socket, :effects, socket.assigns.effects |> List.
    # |> stream_insert(:effects, %{id: effect.id, enabled: status, effect: effect})
    {:noreply, socket}
  end

  def handle_info({:execute_effect, effect_id, input}, socket) do
    user = socket.assigns.user
    effect = Repo.get!(Effect, effect_id)

    case Mixery.EffectHandler.execute(user, effect, input) do
      :ok -> {:noreply, socket}
      {:error, reason} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_info, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("redeem", %{"effect-id" => effect_id}, socket) do
    dbg({:clicked, effect_id})

    send(self(), {:execute_effect, effect_id, nil})
    {:noreply, socket}
  end

  @impl true
  def handle_event(_, _, socket) do
    {:noreply, socket}
  end
end
