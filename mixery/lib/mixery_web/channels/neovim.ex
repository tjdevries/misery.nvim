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

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (neovim:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Event.Reward{redemption: redemption, status: :fulfilled}, socket) do
    broadcast(socket, redemption.reward.key, redemption)
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
