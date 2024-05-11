defmodule Mixery.Twitch do
  alias Mixery.Repo
  alias Mixery.Twitch.User

  def upsert_user(id, attrs) do
    # Old Way
    # %User{id: id}
    # |> User.changeset(attrs)
    # |> Repo.insert!(returning: true, on_conflict: :replace_all, conflict_target: :id)

    case Repo.get(User, id) do
      nil -> %User{id: id}
      post -> post
    end
    |> User.changeset(attrs)
    |> Repo.insert_or_update!()
  end
end
