defmodule Mix.Tasks.UpdateProfilePictures do
  use Mix.Task

  alias Mixery.Repo
  import Ecto.Query

  alias Mixery.Twitch.User

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    auth = TwitchAPI.AuthStore.get(Mixery.Twitch.AuthStore)

    Enum.each(Repo.all(from u in User, where: is_nil(u.profile_image_url)), fn user ->
      twitch_user_id = user.id
      response = TwitchAPI.get(auth, "/users", params: %{id: twitch_user_id})

      case response do
        {:ok, %Req.Response{body: %{"data" => [user_map]}}} ->
          dbg(user_map)

          Repo.get(User, twitch_user_id)
          |> Ecto.Changeset.change(%{profile_image_url: user_map["profile_image_url"]})
          |> Repo.update!()

          :ok

        {:error, req} ->
          dbg({:twitch_profile_url_failed, req})

          :ok
      end
    end)
  end
end
