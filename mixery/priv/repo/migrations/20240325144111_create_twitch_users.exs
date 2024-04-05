defmodule Mixery.Repo.Migrations.CreateTwitchUsers do
  use Ecto.Migration

  def change do
    create table(:twitch_users, primary_key: false) do
      add :id, :string, primary_key: true
      add :login, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
