defmodule Mixery.Job do
  use Oban.Worker, queue: :default

  alias Mixery.Repo
  alias Mixery.Effect
  alias Mixery.EffectStatus
  alias Mixery.Event

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = _) do
    dbg("we in oban now?")

    case args["id"] do
      "enable-status" ->
        %EffectStatus{
          effect_id: args["effect_id"],
          status: :enabled
        }
        |> EffectStatus.changeset(%{})
        |> Repo.insert!()

        effect = Repo.get!(Effect, args["effect_id"])
        Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: :enabled})

      "execute" ->
        effect = Repo.get!(Effect, args["effect_id"])

        case effect do
          %{cooldown: cooldown} when is_number(cooldown) and cooldown > 0 ->
            dbg({:timeout, effect})

            %EffectStatus{
              effect_id: args["effect_id"],
              status: :timeout
            }
            |> EffectStatus.changeset(%{})
            |> Repo.insert!()

            Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: :timeout})

            %{id: "enable-status", effect_id: effect.id}
            |> new(schedule_in: cooldown)
            |> Oban.insert!()

          _ ->
            dbg({:norestrictions, effect})
            nil
        end

      _ ->
        nil
    end

    :ok
  end

  def execute_event(effect_id) do
    %{id: "execute", effect_id: effect_id} |> new() |> Oban.insert!()
  end
end
