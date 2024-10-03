defmodule Mixery.Queues.TwitchLive do
  use Oban.Worker, queue: :twitch

  alias Mixery.Event

  @impl Oban.Worker
  def perform(%Oban.Job{} = _) do
    # auth = TwitchAPI.AuthStore.get(Mixery.Twitch.AuthStore)
    # broadcaster_id = "114257969"
    #
    # # Check if currently live
    # case TwitchAPI.get(auth, "/streams",
    #        params: %{
    #          user_id: broadcaster_id,
    #          type: "live",
    #          first: 1
    #        }
    #      ) do
    #   {:ok, %{body: %{"data" => [%{"id" => id, "started_at" => started_at}]}}} ->
    #     Mixery.broadcast_event(%Event.TwitchLiveStreamStart{
    #       id: id,
    #       started_at: started_at
    #     })
    #
    #     {:ok, {id, started_at}}
    #
    #   other ->
    #     {:error, other}
    # end
    :ok
  end
end
