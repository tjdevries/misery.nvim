defmodule Mix.Tasks.CreateRewards do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  alias Mixery.Repo
  alias Mixery.Twitch.ChannelReward

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    IO.puts("Creating Rewards...")

    {:ok, _} = Application.ensure_all_started(:req)

    # opts = Application.fetch_env!(:mixery, :event_sub)
    # {client_id, opts} = Keyword.pop!(opts, :client_id)

    auth = TwitchAPI.AuthStore.get(Mixery.Twitch.AuthStore)

    broadcaster_id = "114257969"

    rewards = [
      # Teej Coin Related
      %{
        id: "garner-10-teej-coins",
        title: "Get Ten (10) Teej Coins",
        prompt: "Garner 10 Teej Coins via Channel Points. NOTE THIS IS NOT A CURRENCY.",
        twitch_reward_cost: 9950
      },
      %{
        id: "garner-teej-coins",
        title: "Get a Teej Coin",
        prompt: "Garner a Teej Coin via Channel Points. NOTE THIS IS NOT A CURRENCY.",
        twitch_reward_cost: 1000
      }
    ]

    Enum.each(rewards, fn new_reward ->
      case Repo.get(ChannelReward, new_reward.id) do
        nil ->
          create_new_reward(auth, broadcaster_id, new_reward)

        reward ->
          case reward_exists(auth, broadcaster_id, reward) do
            true ->
              IO.puts("reward already exists: #{reward.title} -> #{reward.twitch_reward_id}")
              upsert_reward(new_reward, reward.twitch_reward_id)
              update_reward_on_twitch(auth, broadcaster_id, reward.twitch_reward_id, new_reward)

            false ->
              IO.puts("Need to create new reward: #{reward.title} -> #{reward.twitch_reward_id}")
              create_new_reward(auth, broadcaster_id, new_reward)
          end
      end
    end)
  end

  def upsert_reward(new_reward, twitch_reward_id) do
    params =
      new_reward
      |> Map.put(:twitch_reward_id, twitch_reward_id)

    case ChannelReward.changeset(%ChannelReward{}, params)
         |> Repo.insert(on_conflict: :replace_all, conflict_target: :id) do
      {:ok, channel_reward} ->
        IO.puts("updated channel reward: #{twitch_reward_id}")
        dbg(channel_reward)

      {:error, changeset} ->
        IO.puts("error creating new channel_reward: #{inspect(changeset.errors)}")
    end
  end

  def make_twitch_json(new_reward) do
    dbg({:make_twitch_json, new_reward})

    twitch_json =
      Map.drop(new_reward, [:id, :twitch_reward_cost])
      |> Map.put(:is_enabled, false)
      |> Map.put(:cost, new_reward[:twitch_reward_cost])

    twitch_json =
      case new_reward[:max_per_stream] do
        nil -> twitch_json
        _ -> Map.put(twitch_json, :is_max_per_stream_enabled, true)
      end

    twitch_json =
      case new_reward[:max_per_user_per_stream] do
        nil -> twitch_json
        _ -> Map.put(twitch_json, :is_max_per_user_per_stream_enabled, true)
      end

    twitch_json =
      case new_reward[:global_cooldown_seconds] do
        nil -> twitch_json
        _ -> Map.put(twitch_json, :is_global_cooldown_enabled, true)
      end

    twitch_json
  end

  @spec reward_exists(TwitchAPI.Auth.t(), String.t(), ChannelReward.t()) :: boolean()
  def reward_exists(auth, broadcaster_id, reward) do
    case TwitchAPI.get(auth, "/channel_points/custom_rewards",
           params: %{broadcaster_id: broadcaster_id, id: reward.twitch_reward_id}
         ) do
      {:error, %Req.Response{status: 404} = req} ->
        dbg(req)
        false

      {:error, req} ->
        dbg(req)
        false

      {:ok, _} ->
        true
    end
  end

  def update_reward_on_twitch(auth, broadcaster_id, reward_id, new_reward) do
    # PATCH https://api.twitch.tv/helix/channel_points/custom_rewards
    twitch_json = dbg(make_twitch_json(new_reward))

    case TwitchAPI.patch(auth, "/channel_points/custom_rewards",
           params: %{
             broadcaster_id: broadcaster_id,
             id: reward_id
           },
           json: twitch_json
         ) do
      {:ok, %{body: %{"data" => [%{"id" => twitch_reward_id}]}}} ->
        twitch_reward_id

      {:error, req} ->
        dbg({new_reward.id, req})
        raise "couldnt do it"
    end
  end

  def create_new_reward(auth, broadcaster_id, new_reward) do
    twitch_json = make_twitch_json(new_reward)

    twitch_reward_id =
      case TwitchAPI.post(auth, "/channel_points/custom_rewards",
             params: %{broadcaster_id: broadcaster_id},
             json: twitch_json
           ) do
        {:ok, %{body: %{"data" => [%{"id" => twitch_reward_id}]}}} ->
          twitch_reward_id

        {:error, req} ->
          dbg({new_reward.id, req})
          raise "couldnt do it"
      end

    IO.puts("created new reward: #{new_reward[:title]} -> #{twitch_reward_id}")

    params =
      new_reward
      |> Map.put(:twitch_reward_id, twitch_reward_id)

    case ChannelReward.changeset(%ChannelReward{}, params)
         |> Repo.insert(on_conflict: :replace_all, conflict_target: :id) do
      {:ok, channel_reward} ->
        IO.puts("created new channel_reward: #{twitch_reward_id}")
        dbg(channel_reward)

      {:error, changeset} ->
        IO.puts("error creating new channel_reward: #{inspect(changeset.errors)}")
    end
  end
end
