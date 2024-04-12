defmodule Mixery.Repo.Migrations.CreateChannelRewards do
  use Ecto.Migration

  def change do
    create table(:channel_rewards, primary_key: false) do
      add :id, :string, primary_key: true
      add :twitch_reward_id, :string, null: false
      add :twitch_reward_cost, :integer, null: false
      add :title, :string, null: false
      add :prompt, :string, null: false
      add :is_user_input_required, :boolean, default: false, null: false
      add :max_per_stream, :integer, null: true
      add :max_per_user_per_stream, :integer, null: true
      add :global_cooldown_seconds, :integer, null: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:channel_rewards, [:twitch_reward_id])
  end
end
