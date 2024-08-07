defmodule Mixery.Themesong do
  use Ecto.Schema

  alias Mixery.Repo

  # @type t :: %__MODULE__{
  #         id: pos_integer(),
  #         twitch_user: Mixery.Twitch.User.t(),
  #         key: String.t()
  #       }

  schema "themesongs" do
    belongs_to(:twitch_user, Mixery.Twitch.User, type: :string)
    field(:name, :string)
    field(:path, :string)
    field(:length_ms, :integer)

    # timestamps(type: :utc_datetime)
  end

  def get() do
    Repo.all(__MODULE__)
  end
end
