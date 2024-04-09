defmodule Mixery.Event.Reward do
  @type t :: %__MODULE__{
          redemption: Mixery.Twitch.RewardRedemption.t(),
          status: :fulfilled | :canceled
        }
  defstruct [:redemption, :status]
end
