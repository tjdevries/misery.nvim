defmodule Mixery.Effect do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Mixery.Repo

  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :prompt,
             :cost,
             :is_user_input_required,
             :enabled_on,
             :cooldown,
             :max_per_stream,
             :max_per_user_per_stream,
             :inserted_at,
             :updated_at
           ]}

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          prompt: String.t(),
          cost: pos_integer(),
          is_user_input_required: boolean(),
          enabled_on: :always | :rewrite | :neovim | :never,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :string, []}
  schema "effects" do
    field :title, :string
    field :prompt, :string
    field :cost, :integer

    field :is_user_input_required, :boolean, default: false
    field :enabled_on, Ecto.Enum, values: [:always, :rewrite, :neovim, :never], default: :always

    field :cooldown, :integer
    field :max_per_stream, :integer
    field :max_per_user_per_stream, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(effect, attrs) do
    effect
    |> cast(attrs, [:title, :prompt, :cost, :is_user_input_required, :enabled_on])
    |> validate_required([:title, :prompt, :cost])
  end

  @spec get_status(%__MODULE__{}) :: %Mixery.EffectStatus{}
  def get_status(%__MODULE__{id: id}) do
    get_status(id)
  end

  @spec get_status(String.t()) :: %Mixery.EffectStatus{}
  def get_status(id) when is_binary(id) do
    from(s in Mixery.EffectStatus, where: s.effect_id == ^id)
    |> Ecto.Query.first(:inserted_at)
    |> Repo.one()
  end
end
