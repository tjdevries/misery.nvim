defmodule Mixery.Twitch.ChannelReward do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:twitch_reward_id, :key, :title, :prompt]}

  @type t :: %__MODULE__{
          id: String.t(),
          twitch_reward_id: String.t(),
          twitch_reward_cost: pos_integer(),
          key: String.t(),
          title: String.t(),
          prompt: String.t(),
          coin_cost: pos_integer() | nil,
          is_user_input_required: boolean(),
          max_per_stream: pos_integer() | nil,
          max_per_user_per_stream: pos_integer() | nil,
          global_cooldown_seconds: pos_integer() | nil,
          enabled_on: :always | :rewrite | :neovim | :never,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "channel_rewards" do
    field :twitch_reward_id, :string
    field :twitch_reward_cost, :integer
    field :key, :string
    field :title, :string
    field :prompt, :string
    field :coin_cost, :integer
    field :is_user_input_required, :boolean, default: false

    field :max_per_stream, :integer
    field :max_per_user_per_stream, :integer
    field :global_cooldown_seconds, :integer

    field :enabled_on, Ecto.Enum, values: [:always, :rewrite, :neovim, :never], default: :always

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel_reward, attrs) do
    channel_reward
    |> cast(attrs, [
      :twitch_reward_id,
      :twitch_reward_cost,
      :coin_cost,
      :key,
      :title,
      :prompt,
      :enabled_on,
      :max_per_stream,
      :max_per_user_per_stream,
      :global_cooldown_seconds,
      :is_user_input_required
    ])
    |> validate_required([
      :twitch_reward_id,
      :twitch_reward_cost,
      :coin_cost,
      :key,
      :title,
      :prompt,
      :enabled_on
    ])
  end
end
