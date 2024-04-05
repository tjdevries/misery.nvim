defmodule Mixery.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Mixery.Accounts` context.
  """

  def unique_twitch_email, do: "twitch#{System.unique_integer()}@example.com"
  def valid_twitch_password, do: "hello world!"

  def valid_twitch_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_twitch_email(),
      password: valid_twitch_password()
    })
  end

  def twitch_fixture(attrs \\ %{}) do
    {:ok, twitch} =
      attrs
      |> valid_twitch_attributes()
      |> Mixery.Accounts.register_twitch()

    twitch
  end

  def extract_twitch_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
