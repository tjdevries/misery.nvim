defmodule MixeryWeb.EffectInputComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form class="text-black" phx-target={@myself} phx-submit="save" phx-change="change">
        <div><%= @input %></div>
        <input name="user_input" type="text" value={@input} />
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(:input, assigns.input) |> assign(:effect_id, assigns.effect_id)}
  end

  @impl true
  def handle_event("change", %{"user_input" => text}, socket) do
    {:noreply, socket |> assign(:input, text)}
  end

  def handle_event("save", _, socket) do
    send(self(), {:execute_effect, socket.assigns.effect_id, socket.assigns.input})
    {:noreply, socket}
  end
end
