defmodule Mixery.Twitch do
  alias Mixery.Repo
  alias Mixery.Twitch.User

  def upsert_user(id, attrs) do
    %User{id: id}
    |> User.changeset(attrs)
    |> Repo.insert!(returning: true, on_conflict: :replace_all, conflict_target: :id)
  end
end
