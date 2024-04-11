defmodule Mixery.EffectLedger do
  use Ecto.Schema
  import Ecto.Changeset

  schema "effect_ledger" do
    field :reason, :string
    field :prompt, :string
    field :cost, :integer
    field :effect_id, :string
    field :twitch_user_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(effect_ledger, attrs) do
    effect_ledger
    |> cast(attrs, [:prompt, :cost, :reason])
    |> validate_required([:prompt, :cost, :reason])
  end
end
