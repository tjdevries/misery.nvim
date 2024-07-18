defmodule Mixery do
  @moduledoc """
  Mixery keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @chat_event "chat-event"
  @coin_event "coin-event"
  @effect_status_update_event "effect-status-update-event"
  @execute_effect_event "execute-effect-event"
  @neovim_connection_event "neovim-connection-event"
  @neovim_events "neovim-events"
  @notification_event "notification-event"
  @notification_ended_event "notification-ended-event"
  @reward_event "reward-event"
  @reward_status_update_event "reward-status-update-event"
  @send_chat_event "send-chat-event"
  @subscription_event "subscription-event"
  @twitch_live_stream_event "twitch-live-stream-event"

  alias Mixery.Event

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(Mixery.PubSub, topic, message)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Mixery.PubSub, topic)
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(Mixery.PubSub, topic)
  end

  def broadcast_event(%Event.TwitchLiveStreamStart{} = event) do
    broadcast(@twitch_live_stream_event, event)
  end

  def broadcast_event(%Event.Chat{} = event) do
    broadcast(@chat_event, event)
  end

  def broadcast_event(%Event.Coin{} = event) do
    broadcast(@coin_event, event)
  end

  def broadcast_event(%Event.Subscription{} = event) do
    broadcast(@subscription_event, event)
  end

  def broadcast_event(%Event.SendChat{} = event) do
    broadcast(@send_chat_event, event)
  end

  def broadcast_event(%Event.Reward{} = event) do
    broadcast(@reward_event, event)
  end

  def broadcast_event(%Event.ExecuteEffect{} = event) do
    broadcast(@execute_effect_event, event)
  end

  def broadcast_event(%Event.ExecuteEffectCompleted{} = event) do
    broadcast(@neovim_events, event)
  end

  def broadcast_event(%Event.NeovimOnKey{} = event) do
    broadcast(@neovim_events, event)
  end

  def broadcast_event(%Event.NeovimConnection{} = event) do
    broadcast(@neovim_connection_event, event)
  end

  def broadcast_event(%Event.EffectStatusUpdate{} = event) do
    broadcast(@effect_status_update_event, event)
  end

  def broadcast_event(%Event.RewardStatusUpdate{} = event) do
    broadcast(@reward_status_update_event, event)
  end

  def broadcast_event(%Event.Notification{} = event) do
    broadcast(@notification_event, event)
  end

  def broadcast_event(%Event.Notification.Ended{} = event) do
    broadcast(@notification_ended_event, event)
  end

  def subscribe_to_twitch_live_stream_events() do
    subscribe(@twitch_live_stream_event)
  end

  def subscribe_to_sub_events() do
    subscribe(@subscription_event)
  end

  def subscribe_to_chat_events() do
    subscribe(@chat_event)
  end

  def subscribe_to_coin_events() do
    subscribe(@coin_event)
  end

  def subscribe_to_send_chat_events() do
    subscribe(@send_chat_event)
  end

  def subscribe_to_reward_events() do
    subscribe(@reward_event)
  end

  def subscribe_to_neovim_connection_events() do
    subscribe(@neovim_connection_event)
  end

  def subscribe_to_effect_status_update_events() do
    subscribe(@effect_status_update_event)
  end

  def subscribe_to_reward_status_update_events() do
    subscribe(@reward_status_update_event)
  end

  def subscribe_to_execute_effect_events() do
    subscribe(@execute_effect_event)
  end

  def subscribe_to_neovim_events() do
    subscribe(@neovim_events)
  end

  def subscribe_to_notifications() do
    subscribe(@notification_event)
  end

  def subscribe_to_notification_ended() do
    subscribe(@notification_ended_event)
  end
end
