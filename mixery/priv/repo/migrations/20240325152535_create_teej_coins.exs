defmodule Mixery.Repo.Migrations.CreateTeejCoins do
  use Ecto.Migration

  def change do
    create table(:teej_coins) do
      add :twitch_user_id, references(:twitch_users, type: :string)
      add :amount, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:teej_coins, [:twitch_user_id])
  end
end
