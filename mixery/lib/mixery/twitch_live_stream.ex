defmodule Mixery.TwitchLiveStream do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  schema "twitch_live_streams" do
    field :started_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(twitch_live_stream, attrs) do
    twitch_live_stream
    |> cast(attrs, [:id, :started_at])
    |> validate_required([:id, :started_at])
  end
end
