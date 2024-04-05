defmodule Mixery.Repo.Migrations.CreateRedemptionLedger do
  use Ecto.Migration

  def change do
    create table(:redemption_ledger) do
      add :twitch_user_id, references(:twitch_users, type: :string)
      add :twitch_reward_id, :string, null: false
      add :twitch_reward_title, :string, null: false
      add :twitch_cost, :integer, null: false
      add :twitch_prompt, :string

      add :key, :string

      timestamps(type: :utc_datetime)
    end
  end
end
