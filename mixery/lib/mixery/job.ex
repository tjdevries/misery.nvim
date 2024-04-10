defmodule Mixery.Job do
  use Oban.Worker, queue: :events

  alias Mixery.EffectStatus
  alias Mixery.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = _) do
    case args["id"] do
      "enable-status" ->
        %EffectStatus{
          effect_id: args["effect_id"],
          status: :enabled
        }
        |> EffectStatus.changeset(%{})
        |> Repo.insert!()
    end

    :ok
  end
end
