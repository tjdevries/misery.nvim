defmodule Mixery.Event.ExecuteEffect do
  @derive Jason.Encoder

  @type t :: %__MODULE__{
          effect: Mixery.Effect.t(),
          user: Mixery.Twitch.User.t(),
          input: String.t() | nil
        }
  defstruct [:effect, :user, :input]
end
