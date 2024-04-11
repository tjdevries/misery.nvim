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
  @reward_event "reward-event"
  @reward_status_update_event "reward-status-update-event"
  @play_video_event "play-video-event"
  @send_chat_event "send-chat-event"
  @subscription_event "subscription-event"

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

  def broadcast_event(%Event.Chat{} = event) do
    broadcast(@chat_event, event)
  end

  def broadcast_event(%Event.Coin{} = event) do
    broadcast(@coin_event, event)
  end

  def broadcast_event(%Event.Subscription.SelfSubscription{} = event) do
    broadcast(@subscription_event, event)
  end

  def broadcast_event(%Event.Subscription.GiftSubscription{} = event) do
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

  def broadcast_event(%Event.NeovimConnection{} = event) do
    broadcast(@neovim_connection_event, event)
  end

  def broadcast_event(%Event.EffectStatusUpdate{} = event) do
    broadcast(@effect_status_update_event, event)
  end

  def broadcast_event(%Event.RewardStatusUpdate{} = event) do
    broadcast(@reward_status_update_event, event)
  end

  def broadcast_event(%Event.PlayVideo{} = event) do
    broadcast(@play_video_event, event)
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

  def subscribe_to_play_video_events() do
    subscribe(@play_video_event)
  end
end
