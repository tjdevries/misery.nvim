defmodule Mixery.Twitch.ApiHandler do
  @moduledoc """
  TwitchEventSub websocket client supervisor.
  See the `t:option/0` type for the required options.
  """
  use GenServer

  import Ecto.Query
  alias Mixery.Repo

  require Logger

  alias Mixery.Coin
  alias Mixery.Event
  alias Mixery.Twitch.ChannelReward

  @status_always true
  @status_neovim true

  @typedoc """
  Twitch app access token with required scopes for the provided `subscriptions`
  """
  @type access_token :: String.t()

  @typedoc """
  The IDs of the channels we're subscribing to or something.
  """
  @type channel_ids :: [String.t()]

  @typedoc """
  Twitch app client id.
  """
  @type client_id :: String.t()

  @typedoc """
  The user ID of the broadcaster or bot user we are using for subscriptions.
  """
  @type user_id :: String.t()

  @typedoc """
  The options accepted (or required) by the Websocket client.
  """
  @type option ::
          {:access_token, access_token()}
          | {:client_id, client_id()}
          | {:user_id, user_id()}

  # The options accepted (and required) by the websocket client.
  @required_opts ~w[user_id client_id access_token ]a

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 10_000
    }
  end

  @doc false
  @spec start_link([option()]) :: Supervisor.on_start()
  def start_link(opts) do
    if not Enum.all?(@required_opts, &Keyword.has_key?(opts, &1)) do
      raise ArgumentError,
        message:
          "missing required options (#{inspect(@required_opts)}), got: #{inspect(Keyword.keys(opts))}"
    end

    # Pull the client ID and access token from the opts and put them into an
    # auth struct for the client.
    {client_id, opts} = Keyword.pop!(opts, :client_id)
    {access_token, opts} = Keyword.pop!(opts, :access_token)

    auth =
      TwitchAPI.Auth.new(client_id)
      |> TwitchAPI.Auth.put_access_token(access_token)

    {user_id, opts} = Keyword.pop!(opts, :user_id)
    _ = opts

    # KEKL not gonna come back to bite me. I'll prove it in six months KEKL
    GenServer.start_link(__MODULE__, %{auth: auth, broadcaster_id: "114257969", user_id: user_id},
      name: __MODULE__
    )
  end

  @doc false
  @impl true
  def init(state) do
    # Make sure we get a chance to cleanup on exit
    Process.flag(:trap_exit, true)

    Mixery.subscribe_to_reward_status_update_events()
    Mixery.subscribe_to_reward_events()
    Mixery.subscribe_to_send_chat_events()

    Repo.all(ChannelReward)
    |> Enum.each(fn reward ->
      set_reward_enabled_status(state, reward.twitch_reward_id, true)
    end)

    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    Repo.all(ChannelReward)
    |> Enum.each(fn reward ->
      set_reward_enabled_status(state, reward.twitch_reward_id, false)
    end)
  end

  @impl true
  def handle_info(%Event.RewardStatusUpdate{reward: reward, status: status}, state) do
    set_reward_enabled_status(state, reward.twitch_reward_id, status)
    {:noreply, state}
  end

  def handle_info(%Event.SendChat{message: message}, state) do
    TwitchAPI.post!(state.auth, "/chat/messages",
      json: %{
        broadcaster_id: state.broadcaster_id,
        sender_id: state.broadcaster_id,
        message: message
      }
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(%Event.Reward{redemption: redemption, status: :fulfilled}, state) do
    case redemption.reward do
      %ChannelReward{key: "garner-teej-coins"} ->
        Coin.insert(redemption.user, 1, redemption.reward.key)

      %ChannelReward{key: "garner-10-teej-coins"} ->
        Coin.insert(redemption.user, 10, redemption.reward.key)

      _ ->
        nil
    end

    update_reward_redemption_status(
      state,
      redemption.twitch_redemption_id,
      redemption.twitch_reward_id,
      :fulfilled
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(%Event.Reward{redemption: redemption, status: :canceled}, state) do
    Logger.info("[TwitchApiHandler] Canceled Reward Redemption: #{inspect(redemption)}")

    update_reward_redemption_status(
      state,
      redemption.twitch_redemption_id,
      redemption.twitch_reward_id,
      :canceled
    )

    {:noreply, state}
  end

  def set_reward_enabled_status(state, twitch_reward_id, is_enabled) do
    TwitchAPI.patch(state.auth, "/channel_points/custom_rewards",
      params: %{
        broadcaster_id: state.broadcaster_id,
        id: twitch_reward_id
      },
      json: %{is_enabled: is_enabled}
    )
  end

  defp update_reward_redemption_status(state, id, reward_id, status) do
    status =
      case status do
        :canceled -> "CANCELED"
        :fulfilled -> "FULFILLED"
        # OMEGALUL
        :cancelled -> "CANCELED"
        :fulfiled -> "FULFILLED"
      end

    # PATCH https://api.twitch.tv/helix/channel_points/custom_rewards/redemptions
    # id	String	Yes	A list of IDs that identify the redemptions to update. To specify more than one ID, include this parameter for each redemption you want to update. For example, id=1234&id=5678. You may specify a maximum of 50 IDs.
    # broadcaster_id	String	Yes	The ID of the broadcaster that’s updating the redemption. This ID must match the user ID in the user access token.
    # reward_id	String	Yes	The ID that identifies the reward that’s been redeemed.
    TwitchAPI.patch(state.auth, "/channel_points/custom_rewards/redemptions",
      params: %{
        id: id,
        broadcaster_id: state.broadcaster_id,
        reward_id: reward_id
      },
      json: %{status: status}
    )
  end
end
