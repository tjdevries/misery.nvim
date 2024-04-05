defmodule Mixery.Repo.Migrations.CreateTwitchAccountsAuthTables do
  use Ecto.Migration

  def change do
    create table(:twitch_accounts) do
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:twitch_accounts, [:email])

    create table(:twitch_accounts_tokens) do
      add :twitch_id, references(:twitch_accounts, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:twitch_accounts_tokens, [:twitch_id])
    create unique_index(:twitch_accounts_tokens, [:context, :token])
  end
end
