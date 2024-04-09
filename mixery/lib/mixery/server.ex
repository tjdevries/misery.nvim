defmodule Mixery.Server do
  use GenServer

  require Logger

  alias Mixery.Coin
  alias Mixery.Event.Subscription

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    Mixery.subscribe_to_reward_events()
    Mixery.subscribe_to_sub_events()

    {:ok, args}
  end

  def handle_info(%Subscription.GiftSubscription{} = gift_sub, state) do
    Logger.info("[Server] got gift subscription event: #{inspect(gift_sub)}")

    # SubGift.t() | CommunitySubGift.t() | ReSub.t()
    {amount, reason} =
      case gift_sub.subscription do
        %Subscription.SubGift{sub_tier: sub_tier, duration: duration} ->
          {Coin.calculate(sub_tier, 1, duration), "gift-subscription"}

        %Subscription.CommunitySubGift{} ->
          # TODO: Confirm that because we use SubGift, we don't have to count these
          # Coin.calculate(sub_tier, total)
          {0, "community-subscription:uncounted"}

        %Subscription.ReSub{} = gift ->
          {Coin.calculate(gift.sub_tier, 1, gift.duration), "gift-subscription:resub"}
      end

    Coin.insert(gift_sub.gifter, amount * 5, reason)

    {:noreply, state}
  end

  def handle_info(%Subscription.SelfSubscription{} = sub, state) do
    amount = Coin.calculate(sub.subscription.sub_tier, 1, sub.subscription.duration)
    Coin.insert(sub.user, amount, "subscription:#{sub.subscription.sub_tier}")

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
