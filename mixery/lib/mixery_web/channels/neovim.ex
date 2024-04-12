defmodule MixeryWeb.Channel.Neovim do
  use MixeryWeb, :channel

  require Logger

  alias Mixery.Event

  @impl true
  def join("neovim:lobby", payload, socket) do
    Mixery.Neovim.Connections.add_connection(self())

    socket =
      case socket.assigns[:subscribed] do
        nil ->
          Mixery.subscribe_to_reward_events()
          Mixery.subscribe_to_execute_effect_events()

          socket |> assign(subscribed: true)

        _ ->
          socket
      end

    if authorized?(payload) do
      {:ok, %{reason: "ShyRyan is a liar liar pants on fire"}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def terminate(_reason, _socket) do
    Mixery.Neovim.Connections.remove_connection(self())
  end

  @impl true
  def handle_in(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Event.Reward{redemption: redemption, status: :fulfilled}, socket) do
    broadcast(socket, redemption.reward.id, redemption)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Event.ExecuteEffect{effect: effect}, socket) do
    broadcast(socket, effect.id, effect)
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
