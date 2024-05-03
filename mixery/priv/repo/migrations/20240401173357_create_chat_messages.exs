defmodule Mixery.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :twitch_user_id, references(:twitch_users, type: :string)
      add :text, :text

      timestamps(type: :utc_datetime)
    end
  end
end
