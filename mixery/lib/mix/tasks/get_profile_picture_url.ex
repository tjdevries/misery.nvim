defmodule Mix.Tasks.GetProfilePic do
  use Mix.Task

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_) do
    {:ok, _} = Application.ensure_all_started(:req)

    %{id: "twitch-profile-url", twitch_user_id: "146616692"}
    |> Mixery.Queues.TwitchProfile.new()
    |> Oban.insert()
  end
end
