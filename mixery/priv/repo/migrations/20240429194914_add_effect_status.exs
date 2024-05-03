defmodule Mixery.Repo.Migrations.AddEffectStatus do
  use Ecto.Migration

  def change do
    alter table(:effect_ledger) do
      add :status, :string
    end
  end
end
