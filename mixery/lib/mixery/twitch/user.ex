defmodule Mixery.Twitch.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :login, :display]}

  @type t :: %__MODULE__{
          id: String.t(),
          login: String.t(),
          display: String.t()
        }

  @primary_key {:id, :string, []}
  schema "twitch_users" do
    field(:login, :string)
    field(:display, :string)
    has_one(:coin, Mixery.Coin)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(twitch_user, attrs \\ %{}) do
    twitch_user
    |> cast(attrs, [:login, :display])
    |> validate_required([:id, :login, :display])
    |> unique_constraint([:id])
  end
end
