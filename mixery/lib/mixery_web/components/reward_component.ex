defmodule MixeryWeb.RewardComponent do
  use Phoenix.Component

  alias MixeryWeb.CoreComponents
  alias Mixery.Twitch.ChannelReward

  attr :balance, :integer, required: true
  attr :reward, ChannelReward, required: true

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
  #   <h2><%= reward.title %></h2>
  # </div>
  # <div class="reward-content">
  #   <div class="capitalize"><%= reward.prompt %></div>
  #
  #   <div>
  #     <button type="button" class="btn">
  #       <span><%= reward.coin_cost %></span>
  #     </button>
  #
  #     <button type="button" class="btn">Redeem</button>
  #   </div>
  # </div>
  #
  # <div class="badge elite">
  #     <h2><%= reward.title %></h2>
  # </div>

  def card(%{balance: balance, reward: %{coin_cost: coin_cost}} = assigns) do
    can_afford = balance > coin_cost

    ~H"""
    <div class="flex flex-col h-full max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700">
      <div class="mb-3 font-normal text-gray-700 dark:text-gray-400">
        <%= @reward.title %>
      </div>
      <div class="inline-flex items-center px-3 py-2 text-sm font-medium text-center text-white rounded-lg">
        <%= @reward.prompt %>
      </div>

      <div class="grid grid-cols-2 gap-2 mt-auto my-auto">
        <div class="flex flex-row justify-center items-center gap-1 border rounded-md">
          <div>
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
          </div>
          <span><%= @reward.coin_cost %></span>
        </div>
        <div class="mt-auto">
          <%= if can_afford do %>
            <CoreComponents.button phx-click="redeem" phx-value-reward-id={@reward.id}>
              Redeem
            </CoreComponents.button>
          <% else %>
            <CoreComponents.button disabled class="disabled:bg-red-700 cursor-not-allowed opacity-50">
              Redeem
            </CoreComponents.button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # def button(assigns) do
  #   ~H"""
  #   <div class="text-center">
  #     <CoreComponents.button disabled class=" disabled:bg-red-700 cursor-not-allowed opacity-50">
  #       <%= @reward.id %>: <%= @reward.key %>. Costs: <%= @reward.coin_cost %> coins
  #     </CoreComponents.button>
  #   </div>
  #   """
  # end

  # do
  #   ~H"""
  #   <p><%= @balance %> <%= @reward.key %></p>
  #   """
  # end

  # <div :if={enabled and reward.coin_cost <= @balance and reward.coin_cost != 0}>
  #   <div phx-click="redeem" phx-value-reward-id={reward_id} class="text-center">
  #     <.button disabled>
  #       <%= reward_id %>: <%= reward.key %>. Costs: <%= reward.coin_cost %> coins
  #     </.button>
  #   </div>
  # </div>
end
