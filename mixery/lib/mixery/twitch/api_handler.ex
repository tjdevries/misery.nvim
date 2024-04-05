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

    Mixery.subscribe_to_neovim_connection_events()
    Mixery.subscribe_to_reward_events()
    Mixery.subscribe_to_send_chat_events()

    Enum.each(Repo.all(ChannelReward), fn reward ->
      enabled =
        case reward.enabled_on do
          :always -> @status_always
          :neovim -> false
          :never -> false
          _ -> false
        end

      set_reward_enabled_status(state, reward.twitch_reward_id, enabled)
    end)

    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    Enum.each(Repo.all(ChannelReward), fn reward ->
      # Disable all the rewards when exiting
      set_reward_enabled_status(state, reward.twitch_reward_id, false)
    end)
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: []}, state) do
    Logger.info("No connections")

    query =
      from r in ChannelReward,
        where: r.enabled_on == ^:neovim

    Enum.each(Repo.all(query), fn reward ->
      set_reward_enabled_status(state, reward.twitch_reward_id, false)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(%Event.NeovimConnection{connections: connections}, state) do
    Logger.info("Connections: #{inspect(connections)}")

    query =
      from r in ChannelReward,
        where: r.enabled_on == ^:neovim

    Enum.each(Repo.all(query), fn reward ->
      set_reward_enabled_status(state, reward.twitch_reward_id, @status_neovim)
    end)

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
  def handle_info(%Event.Reward{redemption: redemption}, state) do
    Logger.info("[TwitchApiHandler] Got reward redemption: #{inspect(redemption)}")

    case redemption.reward do
      %ChannelReward{key: "garner-teej-coins"} ->
        Coin.insert(redemption.user, 1, redemption.reward.key)

      %ChannelReward{key: "garner-10-teej-coins"} ->
        Coin.insert(redemption.user, 10, redemption.reward.key)

      _ ->
        nil
    end

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
end
