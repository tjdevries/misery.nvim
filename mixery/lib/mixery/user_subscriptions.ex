defmodule Mixery.UserSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_subscriptions" do
    field :twitch_user_id, :string
    field :sub_tier, Ecto.Enum, values: [:tier_1, :tier_2, :tier_3]
    field :gifted, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_subscriptions, attrs) do
    user_subscriptions
    |> cast(attrs, [:twitch_user_id, :sub_tier, :gifted])
    |> validate_required([:twitch_user_id, :sub_tier, :gifted])
  end
end
