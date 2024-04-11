defmodule Mixery.Repo.Migrations.AddBackKey do
  use Ecto.Migration

  def change do
    alter table(:channel_rewards) do
      add :key, :string, null: true
    end
  end
end
