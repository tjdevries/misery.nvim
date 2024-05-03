defmodule Mixery.Event.ExecuteEffect do
  @derive Jason.Encoder

  @type t :: %__MODULE__{
          id: String.t(),
          effect: Mixery.Effect.t(),
          user: Mixery.Twitch.User.t(),
          input: String.t() | nil
        }
  defstruct [:id, :effect, :user, :input]
end

defmodule Mixery.Event.ExecuteEffectCompleted do
  @derive Jason.Encoder

  @type t :: %__MODULE__{execution_id: String.t()}
  defstruct [:execution_id]
end
