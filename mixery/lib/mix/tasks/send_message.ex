defmodule Mix.Tasks.SendMessage do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:req)

    auth = TwitchAPI.AuthStore.get(Mixery.Twitch.AuthStore)
    broadcaster_id = "114257969"

    dbg(
      TwitchAPI.get!(auth, "/streams",
        params: %{
          user_id: broadcaster_id,
          type: "live",
          first: 1
        }
      )
    )
  end
end
