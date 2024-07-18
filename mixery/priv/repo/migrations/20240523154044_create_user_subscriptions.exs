defmodule Mixery.Repo.Migrations.CreateUserSubscriptions do
  use Ecto.Migration

  def change do
    create table(:user_subscriptions) do
      add :sub_tier, :string
      add :gifted, :boolean, default: false, null: false
      add :twitch_user_id, references(:twitch_users, on_delete: :nothing, type: :string)

      timestamps(type: :utc_datetime)
    end

    create index(:user_subscriptions, [:twitch_user_id])
  end
end
