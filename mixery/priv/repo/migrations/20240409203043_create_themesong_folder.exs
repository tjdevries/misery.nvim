defmodule Mixery.Repo.Migrations.CreateThemesongFolder do
  use Ecto.Migration

  def change do
    create table(:themesongs) do
      add :twitch_user_id, references(:twitch_users, type: :string)
      add :name, :string
      add :path, :string
      add :length_ms, :integer
    end

    create unique_index(:themesongs, [:twitch_user_id])
  end
end
