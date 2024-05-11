defmodule Mixery.Repo.Migrations.AddTwitchProfileColumn do
  use Ecto.Migration

  def change do
    alter table(:twitch_users) do
      add :profile_image_url, :string
    end
  end
end
