defmodule Mixery.Queues.Twitch do
  use Oban.Worker,
    unique: [period: 60 * 60 * 24 * 7, keys: [:twitch_user_id]],
    queue: :twitch

  alias Mixery.Repo
  alias Mixery.Twitch.User

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = _) do
    case args["id"] do
      "twitch-profile-url" ->
        twitch_user_id = args["twitch_user_id"]

        auth = TwitchAPI.AuthStore.get(Mixery.Twitch.AuthStore)
        response = TwitchAPI.get(auth, "/users", params: %{id: twitch_user_id})

        case response do
          {:ok, %Req.Response{body: %{"data" => [user_map]}}} ->
            # |> Map.put(:profile_image_url, user_map["profile_image_url"])
            # |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)

            Repo.get(User, twitch_user_id)
            |> Ecto.Changeset.change(%{profile_image_url: user_map["profile_image_url"]})
            |> Repo.update!()

            :ok

          {:error, req} ->
            dbg({:twitch_profile_url_failed, req})

            :ok
        end
    end
  end

  def queue_user_profile(twitch_user_id) do
    %{id: "twitch-profile-url", twitch_user_id: twitch_user_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
