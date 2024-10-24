defmodule Mixery.Twitch.EventSubHandler do
  use TwitchEventSub

  require Logger

  alias Mixery.Repo

  alias Mixery.Event
  alias Mixery.Twitch
  alias Mixery.Twitch.Redemption
  alias Mixery.Twitch.RedemptionLedger
  alias Mixery.Twitch.RedemptionHandler

  @impl true
  def handle_event("channel.channel_points_custom_reward_redemption.add", event) do
    user_id = event["user_id"]
    user_login = event["user_login"]
    user_display = event["user_name"]
    Twitch.upsert_user(user_id, %{login: user_login, display: user_display})

    redemption = Redemption.from_event(event)

    case redemption.reward do
      %{} = reward ->
        RedemptionHandler.redeem(redemption.user, reward, redemption.user_input)

      nil ->
        Logger.warning("Unknown reward: #{inspect(redemption)}")

        Repo.insert!(%RedemptionLedger{
          twitch_user_id: redemption.user.id,
          twitch_reward_id: redemption.twitch_reward_id,
          twitch_reward_title: redemption.twitch_reward_title,
          twitch_prompt: redemption.user_input,
          twitch_cost: redemption.twitch_reward_cost
        })
    end
  end

  @impl true
  def handle_event("channel.chat.message", event) do
    Mixery.Twitch.ChatHandler.handle_message(event)
  end

  @impl true
  def handle_event("channel.chat.notification", %{"notice_type" => notice_type} = event) do
    user_id = event["chatter_user_id"]
    user_login = event["chatter_user_login"]
    user_display = event["chatter_user_name"]
    Twitch.upsert_user(user_id, %{login: user_login, display: user_display})

    handle_chat_notification(notice_type, event)
  end

  @impl true
  def handle_event("channel.cheer", event) do
    user_id = event["user_id"]
    user_login = event["user_login"]
    user_display = event["user_name"]
    Twitch.upsert_user(user_id, %{login: user_login, display: user_display})

    # message = event["message"]
    # bits = event["bits"]
    Sentry.capture_message("Unhandled cheer: #{inspect(event)}")
  end

  @impl true
  def handle_event("stream.online", event) do
    dbg({"stream.online", event})

    Mixery.broadcast_event(%Event.TwitchLiveStreamStart{
      id: event["id"],
      started_at: event["started_at"]
    })
  end

  @impl true
  def handle_event(name, event) do
    # TODO: Do something when you get a follow?
    Logger.info("Unhandled event: #{inspect(name)}:#{inspect(event)}")
  end

  def handle_chat_notification("sub", event) do
    dbg({"channel.chat.notification:sub", event})

    Event.Subscription.from_event(event)
    |> Mixery.broadcast_event()
  end

  def handle_chat_notification("community_sub_gift", event) do
    dbg({"channel.chat.notification:community_sub_gift", event})

    Event.Subscription.from_event(event)
    |> Mixery.broadcast_event()
  end

  def handle_chat_notification("sub_gift", event) do
    # sub gift -> give to user
    dbg({"channel.chat.notification:sub_gift", event})

    Event.Subscription.from_event(event)
    |> Mixery.broadcast_event()
  end

  def handle_chat_notification("resub", event) do
    dbg({"channel.chat.notification:resub", event})

    # Should already handle this with channel.subscription.message...
    # TODO: Should calculate how many months since the last time we got their resub message
    # This will make sure even if I'm offline, we can still give them credit
    # OR https://dev.twitch.tv/docs/api/reference/#get-broadcaster-subscriptions use this on startup
    Event.Subscription.from_event(event)
    |> Mixery.broadcast_event()
  end

  def handle_chat_notification("gift_paid_upgrade", event) do
    dbg({"channel.chat.notification:gift_paid_upgrade", event})

    Event.Subscription.from_event(event)
    |> Mixery.broadcast_event()
  end

  def handle_chat_notification("prime_paid_upgrade", event) do
    dbg({"channel.chat.notification:prime_paid_upgrade", event})

    Event.Subscription.from_event(event)
    |> Mixery.broadcast_event()
  end

  def handle_chat_notification("raid", event) do
    dbg({"channel.chat.notification:raid", event})
  end

  def handle_chat_notification("unraid", event) do
    dbg({"channel.chat.notification:unraid", event})
  end

  def handle_chat_notification("pay_it_forward", event) do
    dbg({"channel.chat.notification:pay_it_forward", event})
  end

  def handle_chat_notification("announcement", event) do
    dbg({"channel.chat.notification:announcement", event})
  end

  def handle_chat_notification("bits_badge_tier", event) do
    dbg({"channel.chat.notification:bits_badge_tier", event})
  end

  def handle_chat_notification("charity_donation", event) do
    dbg({"channel.chat.notification:charity_donation", event})
  end

  def handle_chat_notification(_notice_type, event) do
    Logger.info("Unhandled chat.notification: #{inspect(event)}")
  end
end
