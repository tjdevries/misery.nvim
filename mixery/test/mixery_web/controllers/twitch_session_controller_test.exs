defmodule MixeryWeb.TwitchSessionControllerTest do
  use MixeryWeb.ConnCase

  import Mixery.AccountsFixtures

  setup do
    %{twitch: twitch_fixture()}
  end

  describe "POST /login" do
    test "logs the twitch in", %{conn: conn, twitch: twitch} do
      conn =
        post(conn, ~p"/login", %{
          "twitch" => %{"email" => twitch.email, "password" => valid_twitch_password()}
        })

      assert get_session(conn, :twitch_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ twitch.email
      assert response =~ ~p"/twitch_accounts/settings"
      assert response =~ ~p"/logout"
    end

    test "logs the twitch in with remember me", %{conn: conn, twitch: twitch} do
      conn =
        post(conn, ~p"/login", %{
          "twitch" => %{
            "email" => twitch.email,
            "password" => valid_twitch_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_mixery_web_twitch_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the twitch in with return to", %{conn: conn, twitch: twitch} do
      conn =
        conn
        |> init_test_session(twitch_return_to: "/foo/bar")
        |> post(~p"/login", %{
          "twitch" => %{
            "email" => twitch.email,
            "password" => valid_twitch_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, twitch: twitch} do
      conn =
        conn
        |> post(~p"/login", %{
          "_action" => "registered",
          "twitch" => %{
            "email" => twitch.email,
            "password" => valid_twitch_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, twitch: twitch} do
      conn =
        conn
        |> post(~p"/login", %{
          "_action" => "password_updated",
          "twitch" => %{
            "email" => twitch.email,
            "password" => valid_twitch_password()
          }
        })

      assert redirected_to(conn) == ~p"/twitch_accounts/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{
          "twitch" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "DELETE /logout" do
    test "logs the twitch out", %{conn: conn, twitch: twitch} do
      conn = conn |> log_in_twitch(twitch) |> delete(~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :twitch_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the twitch is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :twitch_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
