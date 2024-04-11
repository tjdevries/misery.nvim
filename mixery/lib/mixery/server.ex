defmodule Mixery.Server do
  use GenServer

  require Logger

  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Event.Subscription
  alias Mixery.Repo
  alias Mixery.Media.Playerctl

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    Mixery.subscribe_to_reward_events()
    Mixery.subscribe_to_sub_events()
    Mixery.subscribe_to_chat_events()

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

  def handle_info(
        %Event.Chat{user: %{login: "piq9117", id: id}, is_first_message_today: true},
        state
      ) do
    themesong = Repo.get_by!(Mixery.Themesong, twitch_user_id: id)
    status = Playerctl.status()

    case status do
      :playing ->
        Task.start(fn ->
          # Pause my music
          Playerctl.pause()

          System.cmd("mpv", ["--no-terminal", themesong.path])

          # After themesong is done, start the music again
          Playerctl.play()
        end)

      _ ->
        nil
    end

    {:noreply, state}
  end

  def handle_info(%Event.Chat{user: user, is_first_message_today: true}, state) do
    # Coin.insert(user, Coin.calculate(message), "chat")
    _ = user

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
