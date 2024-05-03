defmodule MixeryWeb.Plugs.Secret do
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    if conn.params["secret"] == System.fetch_env!("TEEJ_SECRET") do
      conn
    else
      conn
      |> Plug.Conn.send_resp(403, "Thanks ShYrYaN - This is a secret route")
      |> Plug.Conn.halt()
    end
  end
end
