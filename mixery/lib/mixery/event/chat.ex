defmodule Mixery.Event.Chat do
  @type t :: %__MODULE__{
          user: Mixery.Twitch.User.t(),
          message: Mixery.Twitch.Message.t(),
          is_first_message_today: boolean()
        }

  # TODO: Remove the extra user OMEGALUL
  defstruct [:user, :message, :is_first_message_today]
end
