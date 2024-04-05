defmodule Mixery.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    belongs_to(:twitch_user, Mixery.Twitch.User, type: :string)
    field :text, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:twitch_user_id, :text])
    |> validate_required([:twitch_user_id, :text])
  end
end
