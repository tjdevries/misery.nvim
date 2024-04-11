defmodule Mixery.Twitch.RedemptionHandler do
  require Logger

  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch.ChannelReward
  alias Mixery.Twitch.Redemption
  alias Mixery.Twitch.RedemptionLedger

  @spec redeem(user :: User.t(), reward :: ChannelReward.t()) :: :ok
  def redeem(user, reward, user_input \\ nil) do
    redemption = Redemption.from_reward(user, reward, user_input)

    Repo.insert!(%RedemptionLedger{
      twitch_user_id: user.id,
      twitch_reward_id: reward.twitch_reward_id,
      twitch_reward_title: reward.title,
      twitch_prompt: user_input,
      twitch_cost: reward.twitch_reward_cost
    })

    Mixery.broadcast_event(%Event.Reward{redemption: redemption, status: :fulfilled})
  end
end
