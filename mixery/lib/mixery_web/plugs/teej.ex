defmodule MixeryWeb.Plugs.Teej do
  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    if get_session(conn, :twitch_id) == "114257969" do
      conn
    else
      conn
      |> Plug.Conn.send_resp(403, "This route is just for teej, sorry!")
      |> Plug.Conn.halt()
    end
  end
end
