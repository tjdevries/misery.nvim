defmodule Mixery.Helper do
  defmacro make_event(name, event) do
    s = Macro.to_string(name)
    broadcast_name = String.to_atom("broadcast_event")
    subscribe_name = String.to_atom("subscribe_to_#{s}_events")

    quote do
      def unquote(broadcast_name)(unquote(event) = payload) do
        broadcast(unquote(s), payload)
      end

      def unquote(subscribe_name)() do
        subscribe(unquote(s))
      end
    end
  end
end

defmodule Mixery do
  @moduledoc """
  Mixery keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defp broadcast(topic, message) do
    Phoenix.PubSub.broadcast(Mixery.PubSub, topic, message)
  end

  defp subscribe(topic) do
    Phoenix.PubSub.subscribe(Mixery.PubSub, topic)
  end

  # defp unsubscribe(topic) do
  #   Phoenix.PubSub.unsubscribe(Mixery.PubSub, topic)
  # end

  require Mixery.Helper

  alias Mixery.Event
  Mixery.Helper.make_event(chat, %Event.Chat{})
  Mixery.Helper.make_event(coin, %Event.Coin{})
  Mixery.Helper.make_event(donation, %Event.Donation{})
  Mixery.Helper.make_event(effect_status_update, %Event.EffectStatusUpdate{})
  Mixery.Helper.make_event(execute_effect, %Event.ExecuteEffect{})
  Mixery.Helper.make_event(neovim, %Event.ExecuteEffectCompleted{})
  Mixery.Helper.make_event(neovim_connection, %Event.NeovimConnection{})
  Mixery.Helper.make_event(neovim_on_key, %Event.NeovimOnKey{})
  Mixery.Helper.make_event(notification, %Event.Notification{})
  Mixery.Helper.make_event(notification_ended, %Event.Notification.Ended{})
  Mixery.Helper.make_event(reward, %Event.Reward{})
  Mixery.Helper.make_event(reward_status_update, %Event.RewardStatusUpdate{})
  Mixery.Helper.make_event(send_chat, %Event.SendChat{})
  Mixery.Helper.make_event(sub, %Event.Subscription{})
  Mixery.Helper.make_event(twitch_live_stream, %Event.TwitchLiveStreamStart{})
end
