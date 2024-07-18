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
    Mixery.subscribe_to_twitch_live_stream_events()

    {:ok, args}
  end

  @impl true
  def handle_info(%Subscription{subscription: %Subscription.GiftSubscription{} = gift_sub}, state) do
    Logger.info("[Server] got gift subscription event: #{inspect(gift_sub)}")

    # SubGift.t() | CommunitySubGift.t() | ReSub.t()
    {amount, reason} =
      case gift_sub.subscription do
        %Subscription.SubGift{
          user_id: user_id,
          user_login: user_login,
          user_display: user_display,
          sub_tier: sub_tier,
          duration: duration
        } ->
          # TODO: Probably want to try and get more info about this user first?
          #     but it's ok for now :)
          Mixery.Twitch.upsert_user(user_id, %{login: user_login, display: user_display})

          %Mixery.UserSubscription{}
          |> Mixery.UserSubscription.changeset(%{
            twitch_user_id: user_id,
            sub_tier: sub_tier,
            gifted: true
          })
          |> Repo.insert!()

          {Coin.calculate(sub_tier, 1, duration), "gift-subscription"}

        %Subscription.CommunitySubGift{} ->
          # TODO: Confirm that because we use SubGift, we don't have to count these
          # Coin.calculate(sub_tier, total)
          {0, "community-subscription:uncounted"}

        %Subscription.ReSub{} = gift ->
          # TODO: Handle resubs here?
          #   I'm not sure if they should count as subs or not in the same way
          # %Mixery.UserSubscription{}
          # |> Mixery.UserSubscription.changeset(%{
          #   twitch_user_id: user_id,
          #   sub_tier: sub_tier,
          #   gifted: true
          # })
          # |> Repo.insert!()

          {Coin.calculate(gift.sub_tier, 1, gift.duration), "gift-subscription:resub"}
      end

    Coin.insert(gift_sub.gifter, amount * 5, reason)

    {:noreply, state}
  end

  def handle_info(%Subscription{subscription: %Subscription.SelfSubscription{} = sub}, state) do
    amount = Coin.calculate(sub.subscription.sub_tier, 1, sub.subscription.duration)
    Coin.insert(sub.user, amount, "subscription:#{sub.subscription.sub_tier}")

    %Mixery.UserSubscription{}
    |> Mixery.UserSubscription.changeset(%{
      twitch_user_id: sub.user.id,
      sub_tier: sub.subscription.sub_tier,
      gifted: false
    })
    |> Repo.insert!()

    {:noreply, state}
  end

  def handle_info(%Event.TwitchLiveStreamStart{id: id, started_at: started_at}, state) do
    Logger.info("[Server] got twitch live stream start event: #{inspect(id)} -> #{started_at}")

    %Mixery.TwitchLiveStream{}
    |> Mixery.TwitchLiveStream.changeset(%{id: id, started_at: started_at})
    |> Repo.insert!(on_conflict: :nothing, conflict_target: :id)

    {:noreply, state}
  end

  def handle_info(
        %Event.Chat{
          user: %Mixery.Twitch.User{id: id} = user,
          message: %Message{
            text: text,
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
    if not String.starts_with?(text, "!themesong") and
         not Mixery.ThemesongLedger.has_played_themesong_today(id) do
      # TODO: Check that they are a subscriber
      themesong = Repo.get_by(Mixery.Themesong, twitch_user_id: id)

      if themesong != nil do
        Mixery.ThemesongLedger.mark_themesong_played(id)
        # Mixery.Media.AudioPlayer.add_to_queue(themesong.path)
        Mixery.broadcast_event(
          Event.Notification.themesong(
            "/themesongs/themesong-#{id}.mp3",
            themesong.name,
            user
          )
        )
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
