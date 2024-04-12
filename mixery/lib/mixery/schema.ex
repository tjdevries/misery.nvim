defmodule Mixery.Schema do
  @moduledoc """
  The base Mixery schema module.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      @primary_key {:id, :string, []}
      @foreign_key_type :string
      # @teej_dv Other project-wide things can go here, too.
    end
  end
end
