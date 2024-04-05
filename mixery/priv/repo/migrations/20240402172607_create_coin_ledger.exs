defmodule Mixery.Repo.Migrations.CreateCoinLedger do
  use Ecto.Migration

  def change do
    create table(:coin_ledger) do
      add :twitch_user_id, references(:twitch_users, type: :string)
      add :amount, :integer, null: false
      add :reason, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
