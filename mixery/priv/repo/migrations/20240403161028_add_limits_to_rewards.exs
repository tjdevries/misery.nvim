defmodule Mixery.Repo.Migrations.AddLimitsToRewards do
  use Ecto.Migration

  def change do
    alter table(:channel_rewards) do
      add :max_per_stream, :integer, null: true
      add :max_per_user_per_stream, :integer, null: true
      add :global_cooldown_seconds, :integer, null: true
    end

    create unique_index(:channel_rewards, [:twitch_reward_id])
    create unique_index(:channel_rewards, [:key])
  end
end
