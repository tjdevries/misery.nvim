defmodule MixeryWeb.EffectComponent do
  use Phoenix.Component

  alias MixeryWeb.CoreComponents
  alias Mixery.Effect

  attr :balance, :integer, required: true
  attr :effect, Effect, required: true

  # <div class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700">
  #     <a href="#">
  #         <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">Noteworthy technology acquisitions 2021</h5>
  #     </a>
  #     <p class="mb-3 font-normal text-gray-700 dark:text-gray-400">Here are the biggest enterprise technology acquisitions of 2021 so far, in reverse chronological order.</p>
  #     <a href="#" class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
  #         Read more
  #         <svg class="rtl:rotate-180 w-3.5 h-3.5 ms-2" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 10">
  #             <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M1 5h12m0 0L9 1m4 4L9 9"/>
  #         </svg>
  #     </a>
  # </div>
  #
  #
  # <div class="badge elite capitalize">
  #   <h2><%= effect.title %></h2>
  # </div>
  # <div class="effect-content">
  #   <div class="capitalize"><%= effect.prompt %></div>
  #
  #   <div>
  #     <button type="button" class="btn">
  #       <span><%= effect.cost %></span>
  #     </button>
  #
  #     <button type="button" class="btn">Redeem</button>
  #   </div>
  # </div>
  #
  # <div class="badge elite">
  #     <h2><%= effect.title %></h2>
  # </div>

  def card(%{balance: balance, effect: %{cost: cost}} = assigns) do
    can_afford = balance >= cost

    # TODO: prompt is not good, send only coin cost to twitch
    prompt =
      case String.split(assigns.effect.prompt, ". ", parts: 2) do
        [_, prompt] -> prompt
        _ -> assigns.effect.prompt
      end

    ~H"""
    <div class="flex flex-col h-full max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700">
      <div class="mb-3 text-center text-orange-600 font-bold rounded-sm capitalize ">
        <%= @effect.title %>
      </div>
      <div class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white rounded-lg">
        <%= prompt %>
      </div>

      <div class="mt-auto">
        <%= if can_afford do %>
          <%= if @effect.is_user_input_required do %>
            <.live_component
              id={"effect-#{@effect.id}"}
              module={MixeryWeb.EffectInputComponent}
              effect_id={@effect.id}
              input=""
            />
          <% else %>
            <CoreComponents.button phx-click="redeem" phx-value-effect-id={@effect.id}>
              <.redeem_button effect={@effect} />
            </CoreComponents.button>
          <% end %>
        <% else %>
          <CoreComponents.button disabled class="disabled:bg-red-700 cursor-not-allowed opacity-50">
            <.redeem_button effect={@effect} />
          </CoreComponents.button>
        <% end %>
      </div>
    </div>
    """
  end

  def redeem_button(assigns) do
    ~H"""
    <div class="flex gap-2 justify-center items-center my-auto">
      <span>Redeem</span>
      <div class="flex my-auto items-center gap-1">
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
        <span><%= @effect.cost %></span>
      </div>
    </div>
    """
  end

  # def button(assigns) do
  #   ~H"""
  #   <div class="text-center">
  #     <CoreComponents.button disabled class=" disabled:bg-red-700 cursor-not-allowed opacity-50">
  #       <%= @effect.id %>: <%= @effect.key %>. Costs: <%= @effect.cost %> coins
  #     </CoreComponents.button>
  #   </div>
  #   """
  # end

  # do
  #   ~H"""
  #   <p><%= @balance %> <%= @effect.key %></p>
  #   """
  # end

  # <div :if={enabled and effect.cost <= @balance and effect.cost != 0}>
  #   <div phx-click="redeem" phx-value-effect-id={effect_id} class="text-center">
  #     <.button disabled>
  #       <%= effect_id %>: <%= effect.key %>. Costs: <%= effect.cost %> coins
  #     </.button>
  #   </div>
  # </div>
end
