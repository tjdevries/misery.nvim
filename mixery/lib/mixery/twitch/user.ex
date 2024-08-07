defmodule Mixery.Twitch.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :login,
             :display,
             :profile_image_url
           ]}

  @type t :: %__MODULE__{
          id: String.t(),
          login: String.t(),
          display: String.t(),
          profile_image_url: String.t()
        }

  @primary_key {:id, :string, []}
  schema "twitch_users" do
    field(:login, :string)
    field(:display, :string)
    field(:profile_image_url, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(twitch_user, attrs \\ %{}) do
    twitch_user
    |> cast(attrs, [:id, :login, :display])
    |> validate_required([:id, :login, :display])
    |> unique_constraint([:id])
  end
end
