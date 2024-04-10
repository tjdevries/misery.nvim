defmodule MixeryWeb.TwitchAuth do
  use MixeryWeb, :verified_routes

  require Logger

  import Plug.Conn
  import Phoenix.Controller

  @user_data_cookie "_mixery_twitch_user_data"

  @doc """
  Logs the twitch in. LOGGING IN THE TWITCH!

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_twitch(conn, user_data, _params \\ %{}) do
    twitch_return_to = get_session(conn, :twitch_return_to)

    conn
    |> renew_session()
    |> put_user_data_in_session(user_data)
    |> redirect(to: twitch_return_to || signed_in_path(conn))
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the twitch out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_twitch(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      MixeryWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> delete_resp_cookie(@user_data_cookie, encrypted: true)
    |> renew_session()
    |> redirect(to: ~p"/")
  end

  def fetch_current_twitch(conn, _opts) do
    {twitch_id, conn} = ensure_twitch_id(conn)
    assign(conn, :current_twitch, twitch_id)
  end

  defp ensure_twitch_id(conn) do
    if twitch_id = get_session(conn, :twitch_id) do
      {twitch_id, conn}
    else
      conn = fetch_cookies(conn, encrypted: [@user_data_cookie])

      if user_data = conn.cookies[@user_data_cookie] do
        {user_data["twitch_id"], put_user_data_in_session(conn, user_data)}
      else
        {nil, conn}
      end
    end
  end

  def on_mount(:mount_current_twitch, _params, session, socket) do
    {:cont, mount_current_twitch(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_twitch(socket, session)

    if socket.assigns.current_twitch do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/auth/twitch/login")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_twitch_is_authenticated, _params, session, socket) do
    socket = mount_current_twitch(socket, session)

    if socket.assigns.current_twitch do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_twitch(socket, session) do
    Phoenix.Component.assign_new(socket, :current_twitch, fn ->
      session["twitch_id"]
    end)
  end

  @doc """
  Used for routes that require the twitch to not be authenticated.
  """
  def redirect_if_twitch_is_authenticated(conn, _opts) do
    if conn.assigns[:current_twitch] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the twitch to be authenticated.

  If you want to enforce the twitch email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_twitch(conn, _opts) do
    if conn.assigns[:current_twitch] do
      conn
    else
      case ensure_twitch_id(conn) do
        {nil, conn} ->
          conn
          |> put_flash(:error, "You must log in to access this page.")
          |> maybe_store_return_to()
          |> redirect(to: ~p"/auth/twitch/login")
          |> halt()

        {_, conn} ->
          conn
      end
    end
  end

  defp put_user_data_in_session(conn, user_data) do
    conn
    |> put_session(:twitch_id, user_data["twitch_id"])
    |> put_session(:twitch_display_name, user_data["display_name"])
    |> put_session(:live_socket_id, "twitch_accounts_sessions:#{user_data["twitch_id"]}")
    |> put_resp_cookie(@user_data_cookie, user_data, encrypt: true)
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :twitch_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
  defp signed_in_path(_conn), do: ~p"/"

  def delete(conn, _params) do
    log_out_twitch(conn)
  end
end
