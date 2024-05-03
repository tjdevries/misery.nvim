defmodule Mixery.EffectLedger do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Jason.Encoder,
    only: [:id, :effect_id, :twitch_user_id, :status]
  }

  schema "effect_ledger" do
    field :reason, :string
    field :prompt, :string
    field :cost, :integer
    field :effect_id, :string
    field :twitch_user_id, :string
    field :status, Ecto.Enum, values: [:queued, :completed]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(effect_ledger, attrs) do
    effect_ledger
    |> cast(attrs, [:prompt, :cost, :reason, :status])
    |> validate_required([:prompt, :cost, :reason, :status])
  end
end

defmodule Mixery.EffectLedgerQueries do
  alias Mixery.Repo
  import Ecto.Query

  alias Mixery.Effect
  alias Mixery.EffectLedger
  alias Mixery.Twitch.User

  def get_queued_executions() do
    Repo.all(
      from execution in EffectLedger,
        where: execution.status == ^:queued,
        join: effect in Effect,
        on: execution.effect_id == effect.id,
        join: user in User,
        on: execution.twitch_user_id == user.id,
        select: {execution.id, user, effect, execution.prompt}
    )
    |> Enum.map(fn {execution_id, user, effect, input} ->
      %Mixery.Event.ExecuteEffect{
        id: execution_id,
        effect: effect,
        user: user,
        input: input
      }
    end)
  end
end
