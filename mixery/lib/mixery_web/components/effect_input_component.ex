defmodule MixeryWeb.EffectInputComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form class="text-black" phx-target={@myself} phx-submit="save" phx-change="change">
        <div class="flex my-auto items-center gap-1">
          <div><input name="user_input" type="text" value={@input} /></div>
          <div class="flex flex-1">
            <svg
              stroke="currentColor"
              fill="currentColor"
              stroke-width="0"
              viewBox="0 0 24 24"
              height="20px"
              width="20px"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M12.0049 22.0029C6.48204 22.0029 2.00488 17.5258
    2.00488 12.0029C2.00488 6.48008 6.48204 2.00293 12.0049
    2.00293C17.5277 2.00293 22.0049 6.48008 22.0049
    12.0029C22.0049 17.5258 17.5277 22.0029 12.0049
    22.0029ZM12.0049 7.76029L7.76224 12.0029L12.0049
                    16.2456L16.2475 12.0029L12.0049 7.76029Z">
              </path>
            </svg>
            <span><%= @cost %></span>
          </div>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:input, assigns.input)
     |> assign(:effect_id, assigns.effect_id)
     |> assign(:cost, assigns.cost)}
  end

  @impl true
  def handle_event("change", %{"user_input" => text}, socket) do
    {:noreply, socket |> assign(:input, text)}
  end

  def handle_event("save", _, socket) do
    send(self(), {:execute_effect, socket.assigns.effect_id, socket.assigns.input})
    {:noreply, socket |> assign(:input, "")}
  end
end
