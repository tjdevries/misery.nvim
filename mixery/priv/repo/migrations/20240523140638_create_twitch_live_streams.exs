defmodule Mixery.Repo.Migrations.CreateTwitchLiveStreams do
  use Ecto.Migration

  def change do
    create table(:twitch_live_streams, primary_key: false) do
      add :id, :string, primary_key: true
      add :started_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
