defmodule Mixery.Twitch.SubTier do
  @type t :: :tier_1 | :tier_2 | :tier_3

  @spec from_string(String.t()) :: t | nil
  def from_string(str) do
    case str do
      "prime" -> :tier_1
      "1000" -> :tier_1
      "2000" -> :tier_2
      "3000" -> :tier_3
      _ -> nil
    end
  end
end
