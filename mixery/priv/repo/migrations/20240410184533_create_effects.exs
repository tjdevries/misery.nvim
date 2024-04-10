defmodule Mixery.Repo.Migrations.CreateEffects do
  use Ecto.Migration

  def change do
    create table(:effects, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :string, null: false
      add :prompt, :string, null: false
      add :cost, :integer

      add :is_user_input_required, :boolean, default: false, null: false
      add :enabled_on, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
