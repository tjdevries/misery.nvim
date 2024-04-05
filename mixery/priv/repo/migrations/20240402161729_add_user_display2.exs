defmodule Mixery.Repo.Migrations.AddUserDisplay do
  use Ecto.Migration

  def change do
    alter table(:twitch_users) do
      add :display, :string
    end
  end
end
