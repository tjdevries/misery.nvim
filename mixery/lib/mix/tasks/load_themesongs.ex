defmodule Mix.Tasks.LoadThemesongs do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  alias Mixery.Repo
  # alias Mixery.Twitch.ChannelReward

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    # Iterate over folder and list all mp3s
    folder = "./priv/static/themesongs/"
    files = File.ls!(folder)

    auth = TwitchAPI.AuthStore.get(Mixery.Twitch.AuthStore)

    Enum.each(files, fn file ->
      file = String.replace(file, ".mp3", "")
      parts = String.split(file, "-")
      user_id = Enum.at(parts, 1)

      dbg({:user_id, user_id})

      user =
        case Mixery.Twitch.get_user(user_id) do
          nil ->
            response =
              TwitchAPI.get!(auth, "/users",
                params: %{
                  id: user_id
                }
              )

            user_data = Enum.at(response.body["data"], 0)

            Mixery.Twitch.upsert_user(user_id, %{
              login: user_data["login"],
              display: user_data["display_name"]
            })

          user ->
            user
        end

      outfile =
        "/home/tjdevries/plugins/misery.nvim/mixery/priv/static/themesongs/themesong-#{user.id}.mp3"

      Repo.insert!(
        %Mixery.Themesong{
          twitch_user_id: user.id,
          name: "#{user.display} has entered the chat!",
          path: outfile,
          length_ms: 0
        },
        on_conflict: :replace_all,
        conflict_target: :twitch_user_id
      )
    end)
  end
end
