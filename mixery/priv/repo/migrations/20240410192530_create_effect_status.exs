defmodule Mixery.Repo.Migrations.CreateEffectStatus do
  use Ecto.Migration

  def change do
    create table(:effect_status) do
      add :status, :string, null: false
      add :effect_id, references(:effects, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:effect_status, [:effect_id])
  end
end
