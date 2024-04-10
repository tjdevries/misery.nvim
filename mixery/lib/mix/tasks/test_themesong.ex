defmodule Mix.Tasks.TestThemesong do
  use Mix.Task

  alias Mixery.Repo
  alias Mixery.Themesong

  @impl Mix.Task
  def run(_args) do
    Repo.insert!(%Themesong{
      twitch_user_id: "103596114",
      name: "piq-dates-your-mom",
      path: "/home/tjdevries/plugins/misery.nvim/mixery/themesongs/piq-dates-your-mom.mp3",
      length_ms: 102 * 1000
    })
  end
end
