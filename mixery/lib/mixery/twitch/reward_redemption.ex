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

  @spec from_reward(User.t(), ChannelReward.t(), String.t() | nil) :: t
  def from_reward(user, reward, user_input \\ nil) do
    %__MODULE__{
      user: user,
      user_input: user_input,
      # TODO: Don't know if this is a good idea
      twitch_redemption_id: UUID.uuid4(),
      twitch_reward_id: reward.twitch_reward_id,
      twitch_reward_cost: reward.twitch_reward_cost,
      twitch_reward_title: reward.title,
      reward: reward
    }
  end
end
