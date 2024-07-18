defmodule MixeryWeb.Channel.Neovim do
  use MixeryWeb, :channel

  require Logger

  alias Mixery.Event
  alias Mixery.EffectLedgerQueries

  @impl true
  def join("neovim:lobby", payload, socket) do
    Mixery.Neovim.Connections.add_connection(self())

    Mixery.Colorschemes.insert_many(payload["colorschemes"])

    socket =
      case socket.assigns[:subscribed] do
        nil ->
          Mixery.subscribe_to_reward_events()
          Mixery.subscribe_to_execute_effect_events()

          socket |> assign(subscribed: true)

        _ ->
          socket
      end

    queued_executions = EffectLedgerQueries.get_queued_executions()

    if authorized?(payload) do
      {:ok, %{reason: "ShyRyan is a liar liar pants on fire", queued: queued_executions}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def terminate(_reason, _socket) do
    Mixery.Neovim.Connections.remove_connection(self())
  end

  @impl true
  def handle_in("effect_execution_completed", %{"execution_id" => execution_id}, socket) do
    Mixery.broadcast_event(%Event.ExecuteEffectCompleted{execution_id: execution_id})
    {:noreply, socket}
  end

  def handle_in("neovim_on_key", %{"key" => key}, socket) do
    Mixery.broadcast_event(%Event.NeovimOnKey{key: key})
    {:noreply, socket}
  end

  def handle_in(msg, params, socket) do
    dbg({:neovim_channel, msg, params})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Event.Reward{redemption: redemption, status: :fulfilled}, socket) do
    broadcast(socket, redemption.reward.id, redemption)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Event.ExecuteEffect{effect: effect} = event, socket) do
    broadcast(socket, effect.id, event)
    {:noreply, socket}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
