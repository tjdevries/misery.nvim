defmodule Mix.Tasks.MigrateCoins do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  alias Mixery.Repo

  alias Mixery.Coin

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:req)

    Repo.all(Coin)
    |> Repo.preload(:twitch_user)
    |> Enum.each(fn coin ->
      Coin.insert(coin.twitch_user, coin.amount, "init: move to ledger")
    end)
  end
end
