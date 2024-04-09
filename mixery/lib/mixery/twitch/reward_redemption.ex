defmodule Mixery.Twitch.RewardRedemption do
  alias Mixery.Repo
  alias Mixery.Twitch
  alias Mixery.Twitch.User
  alias Mixery.Twitch.ChannelReward

  @derive Jason.Encoder
  defstruct [
    :user,
    :user_input,
    :reward,
    :twitch_redemption_id,
    :twitch_reward_id,
    :twitch_reward_title,
    :twitch_reward_cost
  ]

  @type t :: %__MODULE__{
          user: User.t(),
          user_input: String.t(),
          reward: ChannelReward.t() | nil
        }

  @spec from_event(map) :: t
  def from_event(event) do
    twitch_reward_id = event["reward"]["id"]
    reward = Repo.get_by(ChannelReward, twitch_reward_id: twitch_reward_id)

    user =
      Twitch.upsert_user(event["user_id"], %{
        login: event["user_login"],
        display: event["user_name"]
      })

    %__MODULE__{
      user: user,
      user_input: event["user_input"],
      twitch_redemption_id: event["id"],
      twitch_reward_id: twitch_reward_id,
      twitch_reward_cost: event["reward"]["cost"],
      twitch_reward_title: event["reward"]["title"],
      reward: reward
    }
  end
end
