defmodule Mixery.ThemesongLedger do
  alias Mixery.Repo
  import Ecto.Query

  use Ecto.Schema
  import Ecto.Changeset

  schema "themesong_ledger" do
    field :twitch_user_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(themesong_ledger, attrs) do
    themesong_ledger
    |> cast(attrs, [])
    |> validate_required([])
  end

  def has_played_themesong_today(%Mixery.Twitch.User{id: id}) do
    has_played_themesong_today(id)
  end

  def has_played_themesong_today(id) do
    recent_livestream =
      from stream in Mixery.TwitchLiveStream,
        select: max(stream.started_at)

    query =
      from th in __MODULE__,
        where: th.inserted_at > subquery(recent_livestream),
        where: th.twitch_user_id == ^id

    Repo.exists?(query)
  end

  def mark_themesong_played(id) do
    Repo.insert!(%__MODULE__{twitch_user_id: id})
  end
end
