defmodule Mixery.Repo.Migrations.RemoveEffectsFromTwitchRewards do
  use Ecto.Migration

  def change do
    alter table(:redemption_ledger) do
      remove :key, :string
    end

    create table(:status_ledger) do
      add :twitch_user_id, references(:twitch_users, type: :string), null: false
      add :effect_id, references(:effects, type: :string), null: false
      add :prompt, :string, null: true
      add :cost, :integer, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
