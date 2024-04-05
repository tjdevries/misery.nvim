defmodule Mixery.Coin do
  require Logger

  alias Mixery.Repo
  alias Mixery.Event

  use Ecto.Schema
  import Ecto.Query

  @derive Jason.Encoder

  @type t :: %__MODULE__{
          user: Twitch.User.t(),
          amount: pos_integer()
        }
  defstruct [:user, :amount]

  defmodule Ledger do
    use Ecto.Schema

    schema "coin_ledger" do
      belongs_to(:twitch_user, Mixery.Twitch.User, type: :string)
      field(:amount, :integer)
      field(:reason, :string)

      timestamps(type: :utc_datetime)
    end
  end

  @spec balance(Mixery.Twitch.User.t()) :: t()
  def balance(user) do
    query =
      from l in Ledger,
        where: l.twitch_user_id == ^user.id

    %__MODULE__{user: user, amount: Repo.aggregate(query, :sum, :amount)}
  end

  @spec gross(Mixery.Twitch.User.t()) :: t()
  def gross(user) do
    query =
      from l in Ledger,
        where: l.twitch_user_id == ^user.id and l.amount > 0

    %__MODULE__{user: user, amount: Repo.aggregate(query, :sum, :amount)}
  end

  def balance_all() do
    query =
      from(l in Ledger,
        join: user in assoc(l, :twitch_user),
        select: {l.twitch_user_id, user.login, user.display, sum(l.amount)},
        where: l.twitch_user_id == user.id,
        group_by: [l.twitch_user_id, user.login, user.display]
      )

    Repo.all(query)
    |> Enum.map(fn {user_id, login, display, amount} ->
      %__MODULE__{
        user: %Mixery.Twitch.User{id: user_id, login: login, display: display},
        amount: amount
      }
    end)
  end

  def gross_all() do
    query =
      from(l in Ledger,
        join: user in assoc(l, :twitch_user),
        select: {l.twitch_user_id, user.login, user.display, sum(l.amount)},
        where: l.twitch_user_id == user.id and l.amount > 0,
        group_by: [l.twitch_user_id, user.login, user.display]
      )

    Repo.all(query)
    |> Enum.map(fn {user_id, login, display, amount} ->
      %__MODULE__{
        user: %Mixery.Twitch.User{id: user_id, login: login, display: display},
        amount: amount
      }
    end)
  end

  def insert(user, amount, reason) do
    %Ledger{twitch_user_id: user.id, amount: amount, reason: reason}
    |> Repo.insert!()

    b = balance(user)

    Mixery.broadcast_event(%Event.Coin{user: user, amount: b.amount, gross: gross(user).amount})
    b
  end

  @spec calculate(Mixery.Twitch.SubTier.t(), integer, integer) :: integer
  def calculate(sub_tier, amount, duration \\ 1) do
    multiplier =
      case sub_tier do
        :tier_1 -> 1
        :tier_2 -> 2
        :tier_3 -> 5
      end

    amount * multiplier * duration
  end
end
