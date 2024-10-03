defmodule Mixery.Event.Donation do
  use TypedStruct

  typedstruct module: TwitchCheer do
    field :user, Mixery.Twitch.User.t()
    field :message, String.t()
    field :amount, pos_integer()
  end

  typedstruct do
    field :data, TwitchCheer.t()
  end

  @spec coins(__MODULE__.t()) :: integer()
  def coins(t) do
    t.data.amount / 100
  end
end
