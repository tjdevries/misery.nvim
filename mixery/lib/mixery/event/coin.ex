defmodule Mixery.Event.Coin do
  @type t :: %__MODULE__{
          user: Twitch.User.t(),
          amount: pos_integer(),
          gross: pos_integer()
        }

  defstruct [:user, :amount, :gross]
end
