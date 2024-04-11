defmodule Mixery.Repo.Migrations.CreateChannelRewards do
  use Ecto.Migration

  def change do
    create table(:channel_rewards) do
      add :twitch_reward_id, :string, null: false
      add :twitch_reward_cost, :integer, null: false
      add :key, :string, null: false
      add :title, :string, null: false
      add :prompt, :string, null: false
      add :is_user_input_required, :boolean, default: false, null: false
      add :enabled_on, :string, null: false
      add :coin_cost, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
