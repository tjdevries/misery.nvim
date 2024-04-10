defmodule Mixery.Effect do
  use Ecto.Schema
  import Ecto.Query

  alias Mixery.Repo

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

    timestamps(type: :utc_datetime)
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
