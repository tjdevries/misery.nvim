defmodule Mixery.OBS.Handler do
  require Logger

  use Fresh

  alias Mixery.Event
  alias Mixery.Twitch.ChannelReward
  alias Mixery.OBS.RequestResponse

  # {:ok, state()}
  # | {:reply, Mint.WebSocket.frame() | [Mint.WebSocket.frame()], state()}

  @impl true
  def handle_connect(status, headers, state) do
    Mixery.subscribe("obs")
    Mixery.subscribe_to_reward_events()

    IO.puts("#{inspect(status)}:#{inspect(headers)}:#{inspect(state)}")
    dbg(status)
    {:ok, state}
  end

  @impl true
  def handle_error(error, state) do
    IO.puts("ERROR TIME:#{inspect(error)}:#{inspect(state)}")
    {:ignore, state}
  end

  @impl true
  def handle_in({:text, msg}, state) do
    decoded = Jason.decode!(msg)
    handle_obs_message(decoded["op"], decoded["d"], state)
  end

  @impl true
  def handle_info({:obs_message, op, msg}, state) do
    send_obs_message(op, msg)
    {:ok, state}
  end

  @impl true
  def handle_info({:obs_request, msg, cb}, state) do
    send_obs_message(:request, msg)
    {:ok, %{state | requests: Map.put(state.requests, msg["requestId"], cb)}}
  end

  @impl true
  def handle_info(%Event.Reward{redemption: redemption}, state) do
    dbg({:obs, redemption})

    case redemption.reward do
      nil ->
        nil

      %ChannelReward{key: "tablet-keyboard"} ->
        send_obs_message(:request, %{
          "requestType" => "SetCurrentProgramScene",
          "requestId" => Ecto.UUID.generate(),
          "requestData" => %{
            "sceneName" => "Primary - with tablet"
          }
        })
    end

    {:ok, state}
  end

  def send_obs_message(op, msg) do
    Fresh.send(self(), obs_message(op, msg))
  end

  # handle hello message
  def handle_obs_message(0, _, state) do
    Logger.info("Got Hello Message")
    {:reply, obs_message(1, %{"rpcVersion" => 1}), state}
  end

  # handle identified message
  def handle_obs_message(2, _, state) do
    Logger.info("Got Identified Message")
    {:ok, state}
  end

  # handle RequestResponse message
  def handle_obs_message(7, msg, state) do
    request_response = RequestResponse.from_map(msg)

    {cb, requests} = Map.pop(state.requests, request_response.request_id)
    if cb, do: cb.(request_response)

    {:ok, %{state | requests: requests}}
  end

  def handle_obs_message(op, msg, state) do
    Logger.warning("Unhandled OBS Message: #{inspect(op)}:#{inspect(msg)}")
    {:ok, state}
  end

  def obs_message(op, d) do
    op =
      case op do
        :hello -> 0
        :identify -> 1
        :identified -> 2
        :request -> 6
        op -> op
      end

    case Jason.encode(%{"op" => op, "d" => d}) do
      {:ok, json} ->
        {:text, json}

      {:error, reason} ->
        Logger.warning("OH NOES: #{inspect(reason)}")
        {:text, reason}
    end
  end
end
