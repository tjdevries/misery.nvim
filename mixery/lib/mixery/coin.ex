defmodule Mixery.Coin do
  require Logger

  alias Mixery.Repo
  alias Mixery.Event

  use TypedStruct
  use Ecto.Schema
  import Ecto.Query

  @derive Jason.Encoder

  typedstruct enforce: true do
    field :user, Mixery.Twitch.User.t()
    field :amount, pos_integer()
  end

  defmodule Ledger do
    use TypedEctoSchema

    typed_schema "coin_ledger" do
      field :amount, :integer
      field :reason, :string

      belongs_to(:twitch_user, Mixery.Twitch.User, type: :string)

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
      from(u in Mixery.Twitch.User,
        join: l in Ledger,
        on: l.twitch_user_id == u.id,
        select: {u, sum(l.amount)},
        group_by: [u.id]
      )

    Repo.all(query)
    |> Enum.map(fn {user, amount} ->
      %__MODULE__{user: user, amount: amount}
    end)
  end

  def gross_all() do
    query =
      from(u in Mixery.Twitch.User,
        join: l in Ledger,
        on: l.twitch_user_id == u.id,
        select: {u, sum(l.amount)},
        where: l.amount > 0,
        group_by: [u.id]
      )

    Repo.all(query)
    |> Enum.map(fn {user, amount} ->
      %__MODULE__{user: user, amount: amount}
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

    # Sometimes twitch sends 0 as the duration... smh
    duration =
      case duration do
        0 -> 1
        duration -> duration
      end

    amount * multiplier * duration
  end
end
