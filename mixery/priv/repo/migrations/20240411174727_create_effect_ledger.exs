defmodule Mixery.Repo.Migrations.CreateEffectLedger do
  use Ecto.Migration

  def change do
    create table(:effect_ledger) do
      add :prompt, :string
      add :cost, :integer
      add :reason, :string
      add :effect_id, references(:effects, type: :string, on_delete: :nothing)
      add :twitch_user_id, references(:twitch_users, type: :string, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:effect_ledger, [:effect_id])
    create index(:effect_ledger, [:twitch_user_id])
  end
end
