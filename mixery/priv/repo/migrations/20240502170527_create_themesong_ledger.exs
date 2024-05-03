defmodule Mixery.Repo.Migrations.CreateThemesongLedger do
  use Ecto.Migration

  def change do
    create table(:themesong_ledger) do
      add :twitch_user_id, references(:twitch_users, on_delete: :nothing, type: :string)

      timestamps(type: :utc_datetime)
    end

    create index(:themesong_ledger, [:twitch_user_id])
  end
end
