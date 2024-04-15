defmodule Mixery.EffectHandler do
  require Logger

  alias Mixery.Coin
  alias Mixery.Effect
  alias Mixery.EffectLedger
  alias Mixery.Event
  alias Mixery.Repo
  alias Mixery.Twitch.User

  @spec execute(User.t(), Effect.t(), String.t() | nil) :: :ok | {:error, String.t()}
  def execute(user, effect, user_input \\ nil) do
    cost = effect.cost

    case Coin.balance(user).amount do
      nil ->
        {:error, "No balance: @#{user.display} / Required: #{cost}"}

      amount when amount < effect.cost ->
        {:error, "Insufficient balance: @#{user.display}. Balance: #{amount} / Required: #{cost}"}

      amount when amount >= effect.cost ->
        Coin.insert(user, -effect.cost, "effect_execute:#{effect.id}")

        %EffectLedger{
          effect_id: effect.id,
          twitch_user_id: user.id,
          prompt: user_input,
          reason: "execute-effect",
          cost: effect.cost
        }
        |> Repo.insert!()

        # TODO: This maybe should always happen together?
        Mixery.broadcast_event(%Event.ExecuteEffect{effect: effect, user: user, input: user_input})

        Mixery.Job.execute_event(user.id, effect.id)

        :ok
    end
  end
end
