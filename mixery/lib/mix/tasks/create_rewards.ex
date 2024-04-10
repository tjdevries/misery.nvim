defmodule Mix.Tasks.CreateRewards do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  import Ecto.Query
  alias Mixery.Repo

  alias Mixery.Twitch.ChannelReward

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    IO.puts("Creating Rewards...")

    {:ok, _} = Application.ensure_all_started(:req)

    opts = Application.fetch_env!(:mixery, :event_sub)
    {client_id, opts} = Keyword.pop!(opts, :client_id)
    {access_token, _} = Keyword.pop!(opts, :access_token)

    auth =
      TwitchAPI.Auth.new(client_id)
      |> TwitchAPI.Auth.put_access_token(access_token)

    broadcaster_id = "114257969"
    timeout_minute = 1

    effects = [
      %{
        id: "suit-up",
        cost: 5,
        title: "Put on a Suit Coat",
        prompt: "Have TJ put on a suit coat for the rest of the stream.",
        enabled_on: :always
        # max_per_stream: 1
      },
      %{
        id: "marimba",
        cost: 50,
        title: "Play the Marimba",
        prompt:
          "I will play one of the two songs I can actually play right now. I will practice more later.",
        enabled_on: :always
        # max_per_stream: 1
      },
      %{
        id: "wordle",
        cost: 50,
        title: "Solve today's Wordle Puzzle",
        prompt:
          "I'll solve today's wordle. If I fail, I delete a file of your choosing from my config",
        is_user_input_required: true,
        enabled_on: :always
        # max_per_stream: 1
      },
      %{
        id: "leetcode",
        cost: 50,
        title: "Solve a LeetCode easy first try",
        prompt:
          "If I don't get it first try, I'll delete a file of your choosing from my config.",
        is_user_input_required: true,
        enabled_on: :always
        # max_per_stream: 1
      },
      %{
        id: "switch-seat",
        cost: 5,
        title: "Make me switch to a different seat",
        prompt:
          "Choose between 'chair', 'ball', 'standing' until someone else chooses or one hour (whichever is sooner)",
        enabled_on: :always
        # global_cooldown_seconds: 5 * timeout_minute
      },
      %{
        id: "delete-random-file",
        coin_cost: 100,
        title: "Delete random file in nvim config",
        prompt:
          "Delete a random file in my neovim config. I cannot undo the delete or use git to retrieve it.",
        enabled_on: :rewrite
        # global_cooldown_seconds: 15 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 250,
        key: "delete-chosen-file",
        title: "Pick a file to delete in neovim config",
        prompt:
          "Pick a file to delete in my neovim config. I cannot undo the delete or use git to retrieve it. NOTE: if you pick a file that doesn't exist, no refunds! :)",
        enabled_on: :rewrite,
        global_cooldown_seconds: 15 * timeout_minute
      },
      # Skip song
      %{
        twitch_reward_cost: 1,
        key: "pick-colorscheme",
        title: "Pick a colorscheme",
        prompt: "Must be a valid colorscheme name (no refunds).",
        is_user_input_required: true,
        enabled_on: :neovim,
        coin_cost: 2
      },
      %{
        twitch_reward_cost: 1,
        key: "random-colorscheme",
        title: "Random colorscheme",
        prompt: "Will pick a random colorscheme.",
        enabled_on: :neovim,
        coin_cost: 1
      },
      %{
        twitch_reward_cost: 1,
        key: "fog-of-war",
        title: "Fog of War",
        prompt: "Shines flashlight in the darkness of code.",
        enabled_on: :neovim,
        coin_cost: 5,
        global_cooldown_seconds: 2 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        key: "invisaline",
        title: "Invisialine",
        prompt: "Makes current line invisible.",
        enabled_on: :neovim,
        coin_cost: 5
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 5,
        key: "hide-cursor",
        title: "Hide my cursor",
        prompt: "I will be unable to see my cursor at all.",
        enabled_on: :neovim,
        global_cooldown_seconds: 30 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 15,
        key: "snake",
        title: "MODE: Snake Mode",
        prompt: "Only locations I recently visited will be visible, similar to the game 'snake'",
        enabled_on: :neovim,
        global_cooldown_seconds: 30 * timeout_minute
      },
      # Add on-screen keyboard only
      %{
        twitch_reward_cost: 1,
        key: "on-screen-keyboard",
        title: "MODE: On Screen Keyboard",
        prompt: "I can only use the on screen keyboard to type (including vim motions).",
        enabled_on: :rewrite,
        coin_cost: 5
      },
      # Add tablet-writing only
      %{
        twitch_reward_cost: 1,
        key: "tablet-keyboard",
        title: "MODE: Tablet Handwriting Only",
        prompt:
          "I can only use my tablet to type via handwriting-to-text (including vim motions).",
        enabled_on: :rewrite,
        coin_cost: 5
      },
      %{
        twitch_reward_cost: 1,
        key: "delayed-keyboard",
        title: "MODE: Keyboard 3 Second Delay",
        prompt:
          "We intercept every keystroke that I send to the computer and delay it 3 seconds before executing it",
        enabled_on: :rewrite,
        coin_cost: 15
      },
      # Editors
      %{
        twitch_reward_cost: 1,
        coin_cost: 50,
        key: "chat-gpt-only",
        title: "EDITOR: Only can copy/paste chat gpt",
        prompt:
          "Use ChatGPT as my editor. I cannot type anything into nvim. Only allowed to copy/paste to-and-from chat gpt.",
        enabled_on: :rewrite
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 100,
        key: "vs-c*de",
        title: "EDITOR: Use VS C*de for 15 minutes",
        prompt: "Only allowed to use default VS C*de for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 50,
        key: "emacs",
        title: "EDITOR: Use Emacs for 15 minutes",
        prompt: "Open default Emacs for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 50,
        key: "ed",
        title: "EDITOR: Use `ed` for 15 minutes",
        prompt: "Open the default editor (ed) for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 50,
        key: "libre-office",
        title: "EDITOR: Use libre-office for 15 minutes",
        prompt: "Open the libre-office for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 15,
        key: "right-to-left",
        title: "EDITOR: set rightoleft",
        prompt: "Sets the editor to 'righttoleft' mode, which makes everything backwards",
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * timeout_minute
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 15,
        key: "screen-upside-down",
        title: "Rotate screen upside-down",
        prompt: "Rotates my entire monitor 180 degrees (upside-down).",
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * timeout_minute
      },
      #
      %{
        twitch_reward_cost: 1,
        # TODO: This is way too low
        coin_cost: 10,
        key: "no-going-back",
        title: "No Going Back",
        prompt: "If my cursor moves backwards at all, the entire file is deleted.",
        is_user_input_required: false,
        enabled_on: :rewrite
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 5,
        key: "random-font",
        title: "Pick a Random Font",
        prompt: "Sets a random font in my terminal",
        is_user_input_required: false,
        enabled_on: :rewrite
      },
      %{
        twitch_reward_cost: 1,
        coin_cost: 15,
        key: "peace-mode",
        title: "Peaceful Editing",
        prompt: "Five minutes of peaceful editing for teej",
        is_user_input_required: false,
        enabled_on: :rewrite,
        global_cooldown_seconds: 60 * 60
      },
      # Currently only via neovim?... But could be other places I guess
      %{
        twitch_reward_cost: 1,
        coin_cost: 50,
        key: "jumpscare",
        title: "JUMPSCARE",
        prompt: "Play something loud to scare me. And chat.",
        is_user_input_required: false,
        enabled_on: :neovim
      }
    ]

    effects
    |> Enum.each(fn effect ->
      dbg(effect)
    end)

    rewards = [
      # Teej Coin Related
      %{
        twitch_reward_cost: 9950,
        coin_cost: 0,
        key: "garner-10-teej-coins",
        title: "Get Ten (10) Teej Coins",
        prompt: "Garner 10 Teej Coins via Channel Points. NOTE THIS IS NOT A CURRENCY.",
        enabled_on: :always
      },
      %{
        twitch_reward_cost: 1000,
        coin_cost: 0,
        key: "garner-teej-coins",
        title: "Get a Teej Coin",
        prompt: "Garner a Teej Coin via Channel Points. NOTE THIS IS NOT A CURRENCY.",
        enabled_on: :always
      }
    ]

    Enum.each(rewards, fn new_reward ->
      new_reward =
        case new_reward[:coin_cost] do
          cost when cost in [nil, 0] ->
            new_reward

          cost ->
            Map.put(
              new_reward,
              :prompt,
              "Costs #{cost} coin(s). #{new_reward[:prompt]}"
            )
        end

      query =
        from reward in ChannelReward,
          where: reward.key == ^new_reward[:key],
          limit: 1

      case Repo.one(query) do
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
         |> Repo.insert(on_conflict: :replace_all) do
      {:ok, channel_reward} ->
        IO.puts("updated channel reward: #{twitch_reward_id}")
        dbg(channel_reward)

      {:error, changeset} ->
        IO.puts("error creating new channel_reward: #{inspect(changeset.errors)}")
    end
  end

  def make_twitch_json(new_reward) do
    dbg({:make_twitch_json, new_reward})
    twitch_reward_cost = new_reward[:twitch_reward_cost]

    twitch_json =
      Map.drop(new_reward, [:key, :enabled_on, :twitch_reward_cost, :coin_cost])
      |> Map.put(:is_enabled, false)
      |> Map.put(:cost, twitch_reward_cost)

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

    case twitch_json[:coin_cost] do
      cost when cost in [nil, 0] ->
        twitch_json

      cost ->
        Map.put(
          twitch_json,
          :prompt,
          "Costs #{cost} coin(s). #{twitch_json[:prompt]}"
        )
    end
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
    key = new_reward[:key]
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
        dbg({key, req})
        raise "couldnt do it"
    end
  end

  def create_new_reward(auth, broadcaster_id, new_reward) do
    key = new_reward[:key]

    twitch_json = make_twitch_json(new_reward)

    twitch_reward_id =
      case TwitchAPI.post(auth, "/channel_points/custom_rewards",
             params: %{broadcaster_id: broadcaster_id},
             json: twitch_json
           ) do
        {:ok, %{body: %{"data" => [%{"id" => twitch_reward_id}]}}} ->
          twitch_reward_id

        {:error, req} ->
          dbg({key, req})
          raise "couldnt do it"
      end

    IO.puts("created new reward: #{new_reward[:title]} -> #{twitch_reward_id}")

    params =
      new_reward
      |> Map.put(:twitch_reward_id, twitch_reward_id)

    case ChannelReward.changeset(%ChannelReward{}, params)
         |> Repo.insert(on_conflict: :replace_all) do
      {:ok, channel_reward} ->
        IO.puts("created new channel_reward: #{twitch_reward_id}")
        dbg(channel_reward)

      {:error, changeset} ->
        IO.puts("error creating new channel_reward: #{inspect(changeset.errors)}")
    end
  end
end
