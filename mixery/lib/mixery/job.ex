defmodule Mixery.Job do
  use Oban.Worker, queue: :default

  import Ecto.Query

  alias Mixery.Repo
  alias Mixery.Effect
  alias Mixery.EffectStatus
  alias Mixery.EffectLedger
  alias Mixery.Event

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = _) do
    case args["id"] do
      "enable-status" ->
        effect = Repo.get!(Effect, args["effect_id"])

        case effect.enabled_on do
          :never ->
            :ok

          :neovim ->
            if Mixery.Neovim.Connections.connected?() do
              enable_effect(effect)
            end

            :ok

          # TODO: Check if we're connected to neovim?
          _ ->
            enable_effect(effect)
        end

      "execute" ->
        effect = Repo.get!(Effect, args["effect_id"])

        case effect do
          %{cooldown: cooldown} when is_number(cooldown) and cooldown > 0 ->
            timeout_effect(effect, cooldown)

          %{max_per_stream: max_per_stream}
          when is_number(max_per_stream) and max_per_stream > 0 ->
            dbg({:max_per_stream, effect})

            max_per_stream_effect(effect, max_per_stream)

          %{max_per_user_per_stream: max_per_user_per_stream}
          when is_number(max_per_user_per_stream) and max_per_user_per_stream > 0 ->
            dbg({:max_per_user_per_stream, effect})

            max_per_user_per_stream_effect(effect, args["user_id"], max_per_user_per_stream)

          _ ->
            dbg({:norestrictions, effect})
            nil
        end

      _ ->
        nil
    end

    :ok
  end

  def execute_event(user_id, effect_id) do
    %{id: "execute", effect_id: effect_id, user_id: user_id} |> new() |> Oban.insert!()
  end

  defp enable_effect(effect) do
    %EffectStatus{
      effect_id: effect.id,
      status: :enabled
    }
    |> EffectStatus.changeset(%{})
    |> Repo.insert!()

    Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: :enabled})

    :ok
  end

  defp timeout_effect(effect, cooldown) do
    %EffectStatus{
      effect_id: effect.id,
      status: :timeout
    }
    |> EffectStatus.changeset(%{})
    |> Repo.insert!()

    Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: :timeout})

    %{id: "enable-status", effect_id: effect.id}
    |> new(schedule_in: cooldown)
    |> Oban.insert!()
  end

  defp max_per_stream_effect(effect, max_per_stream) do
    query =
      from e in EffectLedger,
        where: e.effect_id == ^effect.id and fragment("date(?) >= CURRENT_DATE", e.inserted_at)

    exexcuted_today = dbg(Repo.aggregate(query, :count, :id))

    if exexcuted_today >= max_per_stream do
      # TODO: This should be not actually scheduled for this, but for the next time we stream...
      #       BUT LOL I DONT CARE FOR NOW
      datetime = DateTime.new!(Date.utc_today() |> Date.add(1), ~T[00:00:00], "Etc/UTC")

      %{id: "enable-status", effect_id: effect.id}
      |> new(scheduled_at: datetime)
      |> Oban.insert!()

      %EffectStatus{
        effect_id: effect.id,
        status: :timeout
      }
      |> EffectStatus.changeset(%{})
      |> Repo.insert!()

      Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: :timeout})
    end
  end

  defp max_per_user_per_stream_effect(effect, user_id, max_per_stream) do
    query =
      from e in EffectLedger,
        where: e.effect_id == ^effect.id,
        where: e.twitch_user_id == ^user_id,
        where: fragment("date(?) >= CURRENT_DATE", e.inserted_at)

    exexcuted_today = dbg(Repo.aggregate(query, :count, :id))

    if exexcuted_today >= max_per_stream do
      # TODO: This should be not actually scheduled for this, but for the next time we stream...
      #       BUT LOL I DONT CARE FOR NOW
      datetime = DateTime.new!(Date.utc_today() |> Date.add(1), ~T[00:00:00], "Etc/UTC")

      %{id: "enable-status", effect_id: effect.id}
      |> new(scheduled_at: datetime)
      |> Oban.insert!()

      %EffectStatus{
        effect_id: effect.id,
        status: :timeout
      }
      |> EffectStatus.changeset(%{})
      |> Repo.insert!()

      Mixery.broadcast_event(%Event.EffectStatusUpdate{effect: effect, status: :timeout})
    end
  end
end
