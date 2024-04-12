defmodule Mixery.Twitch.ChannelReward do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:twitch_reward_id, :title, :prompt]}

  @type t :: %__MODULE__{
          id: String.t(),
          twitch_reward_id: String.t(),
          twitch_reward_cost: pos_integer(),
          title: String.t(),
          prompt: String.t(),
          is_user_input_required: boolean(),
          max_per_stream: pos_integer() | nil,
          max_per_user_per_stream: pos_integer() | nil,
          global_cooldown_seconds: pos_integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :string, []}
  schema "channel_rewards" do
    field :twitch_reward_id, :string
    field :twitch_reward_cost, :integer
    field :title, :string
    field :prompt, :string
    field :is_user_input_required, :boolean, default: false

    field :max_per_stream, :integer
    field :max_per_user_per_stream, :integer
    field :global_cooldown_seconds, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel_reward, attrs) do
    channel_reward
    |> cast(attrs, [
      :id,
      :twitch_reward_id,
      :twitch_reward_cost,
      :title,
      :prompt,
      :max_per_stream,
      :max_per_user_per_stream,
      :global_cooldown_seconds,
      :is_user_input_required
    ])
    |> validate_required([
      :id,
      :twitch_reward_id,
      :twitch_reward_cost,
      :title,
      :prompt
    ])
  end
end
