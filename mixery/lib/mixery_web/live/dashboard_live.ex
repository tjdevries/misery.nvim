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

    case Repo.get(User, twitch_id) do
      nil ->
        socket =
          socket
          |> assign(user: nil)
          |> assign(display: nil)
          |> assign(balance: 0)
          |> assign(gross: 0)
          |> assign(effects: [])

        {:ok, socket}

      user ->
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
          |> Enum.map(fn {status, effect} ->
            %{status: status, effect: effect}
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
  end

  @impl true
  def render(%{user: nil} = assigns) do
    ~H"""
    Send a chat message or something, to make sure this is workin
    """
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <div class="flex flex-col gap-4 text-sm w-full">
      <div class="text-center text-4xl"><%= @user.display %></div>
      <div class="text-center">Twitch ID: <%= @user.id %></div>
      <div class="text-center flex justify-center gap-4">
        <div class="py-2 px-4 rounded-md border-2 border-orange-500">Balance: <%= @balance %></div>
        <div class="py-2 px-4 rounded-md border-2 border-orange-500">Accumulated: <%= @gross %></div>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-4 container mx-auto">
        <EffectComponent.card
          :for={%{status: status, effect: effect} <- @effects}
          balance={@balance}
          status={status}
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
      case index do
        nil ->
          socket

        index ->
          assign(
            socket,
            :effects,
            socket.assigns.effects
            |> List.replace_at(
              index,
              Enum.at(socket.assigns.effects, index) |> Map.put(:status, status)
            )
          )
      end

    # item.enabled = status
    # socket = assign(socket, :effects, socket.assigns.effects |> List.
    # |> stream_insert(:effects, %{id: effect.id, enabled: status, effect: effect})
    {:noreply, socket}
  end

  def handle_info({:execute_effect, effect_id, input}, socket) do
    user = socket.assigns.user
    effect = Repo.get!(Effect, effect_id)

    case Mixery.EffectHandler.execute(user, effect, input) do
      :ok ->
        Process.send_after(self(), :clear_flash, 5000)
        {:noreply, socket |> put_flash(:info, "Successfully executed: '#{effect.id}'")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}
    end
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
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
