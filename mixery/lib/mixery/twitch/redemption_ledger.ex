defmodule Mixery.Twitch.RedemptionLedger do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: pos_integer(),
          twitch_user_id: String.t(),
          twitch_reward_id: String.t(),
          twitch_reward_title: String.t(),
          twitch_cost: pos_integer(),
          twitch_prompt: String.t()
        }

  schema "redemption_ledger" do
    belongs_to(:twitch_user, Mixery.Twitch.User, type: :string)
    field(:twitch_reward_id, :string)
    field(:twitch_reward_title, :string)
    field(:twitch_cost, :integer)
    field(:twitch_prompt, :string)

    timestamps(type: :utc_datetime)
  end
end
