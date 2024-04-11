defmodule Mixery.Event.ExecuteEffect do
  @type t :: %__MODULE__{effect: Mixery.Effect.t()}
  defstruct [:effect]
end
