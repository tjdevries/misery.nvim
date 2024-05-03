defmodule Mixery.Server do
  use GenServer

  require Logger

  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Event.Subscription
  alias Mixery.Repo
  alias Mixery.Twitch.Message

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    Mixery.subscribe_to_reward_events()
    Mixery.subscribe_to_sub_events()
    Mixery.subscribe_to_chat_events()

    {:ok, args}
  end

  @impl true
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
        %Event.Chat{
          user: %Mixery.Twitch.User{id: id} = user,
          message: %Message{
            badges: %Mixery.Twitch.UserBadges{
              subscriber: subscriber,
              moderator: moderator,
              vip: vip
            }
          }
        },
        state
      )
      when subscriber or moderator or vip do
    dbg({:handling_sub_message, id})

    # Coin.insert(user, Coin.calculate(message), "chat")
    if not Mixery.ThemesongLedger.has_played_themesong_today(id) do
      # TODO: Check that they are a subscriber
      themesong = Repo.get_by(Mixery.Themesong, twitch_user_id: id)

      if themesong != nil do
        Mixery.ThemesongLedger.mark_themesong_played(id)
        # Mixery.Media.AudioPlayer.add_to_queue(themesong.path)
        Mixery.broadcast_event(%Event.PlayAudio{
          audio_url: "/themesongs/themesong-#{id}.mp3",
          user: user,
          greeting: themesong.name
        })
      end
    end

    {:noreply, state}
  end

  def handle_info(%Event.Chat{} = _message, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
