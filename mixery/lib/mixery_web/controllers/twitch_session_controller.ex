defmodule MixeryWeb.TwitchSessionController do
  use MixeryWeb, :controller

  alias Mixery.Accounts
  alias MixeryWeb.TwitchAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:twitch_return_to, ~p"/twitch_accounts/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"twitch" => twitch_params}, info) do
    %{"email" => email, "password" => password} = twitch_params

    if twitch = Accounts.get_twitch_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> TwitchAuth.log_in_twitch(twitch, twitch_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> TwitchAuth.log_out_twitch()
  end
end
