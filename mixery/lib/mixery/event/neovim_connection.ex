defmodule Mixery.Event.NeovimConnection do
  @type t :: %__MODULE__{connections: [pid]}
  defstruct [:connections]
end
