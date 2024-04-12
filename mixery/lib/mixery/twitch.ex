defmodule Mixery.Twitch do
  alias Mixery.Repo
  alias Mixery.Twitch.User

  def upsert_user(id, attrs) do
    %User{id: id}
    |> User.changeset(attrs)
    |> Repo.insert!(returning: true, on_conflict: :replace_all)
  end

  def upsert_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!(returning: true, on_conflict: :replace_all)
  end

  def get_or_upsert_user(user_id, attrs) do
    case Repo.get(User, user_id) do
      nil ->
        upsert_user(user_id, attrs)

      user ->
        user
    end
  end
end
