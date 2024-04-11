defmodule Mixery.Repo.Migrations.AddCooldowns do
  use Ecto.Migration

  def change do
    alter table(:effects) do
      add :cooldown, :integer, null: true
      add :max_per_stream, :integer, null: true
      add :max_per_user_per_stream, :integer, null: true
    end
  end
end
