defmodule Mixery.Redemption do
  require Logger

  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch.ChannelReward
  alias Mixery.Twitch.RewardRedemption
  alias Mixery.Twitch.RedemptionLedger

  @spec handle_redemption(user :: User.t(), reward :: ChannelReward.t()) :: :ok
  def handle_redemption(user, reward, user_input \\ nil) do
    redemption = RewardRedemption.from_reward(user, reward, user_input)

    case reward do
      %ChannelReward{coin_cost: cost} = reward when cost > 0 ->
        Repo.insert!(%RedemptionLedger{
          twitch_user_id: user.id,
          twitch_reward_id: reward.twitch_reward_id,
          twitch_reward_title: reward.title,
          twitch_prompt: user_input,
          twitch_cost: reward.twitch_reward_cost,
          key: reward.key
        })

        status =
          case Coin.balance(user).amount do
            nil ->
              Mixery.broadcast_event(%Event.SendChat{
                message: "No balance: @#{user.display} / Required: #{cost}"
              })

              :canceled

            amount when amount < reward.coin_cost ->
              Mixery.broadcast_event(%Event.SendChat{
                message:
                  "Insufficient balance: @#{user.display}. Balance: #{amount} / Required: #{cost}"
              })

              :canceled

            amount when amount >= reward.coin_cost ->
              Coin.insert(user, -reward.coin_cost, "redeemed:#{reward.key}")
              :fulfilled
          end

        Mixery.broadcast_event(%Event.Reward{redemption: redemption, status: status})

      reward ->
        Repo.insert!(%RedemptionLedger{
          twitch_user_id: user.id,
          twitch_reward_id: reward.twitch_reward_id,
          twitch_reward_title: reward.title,
          twitch_prompt: user_input,
          twitch_cost: reward.twitch_reward_cost,
          key: reward.key
        })

        Mixery.broadcast_event(%Event.Reward{redemption: redemption, status: :fulfilled})
    end
  end
end
