defmodule Mixery.EffectStatus do
  use Ecto.Schema
  import Ecto.Changeset

  schema "effect_status" do
    belongs_to(:effect, Mixery.Effect, type: :string)
    field :status, Ecto.Enum, values: [:enabled, :timeout, :disabled]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(effect_status, attrs) do
    effect_status
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
