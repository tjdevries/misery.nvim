defmodule Mix.Tasks.SendMessage do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:req)

    opts = Application.fetch_env!(:mixery, :event_sub)
    {client_id, opts} = Keyword.pop!(opts, :client_id)
    {access_token, _} = Keyword.pop!(opts, :access_token)

    auth =
      TwitchAPI.Auth.new(client_id)
      |> TwitchAPI.Auth.put_access_token(access_token)

    broadcaster_id = "114257969"

    dbg(
      TwitchAPI.post(auth, "/chat/messages",
        json: %{
          broadcaster_id: broadcaster_id,
          sender_id: broadcaster_id,
          message: "yayayaya"
        }
      )
    )

    dbg({:hello})
  end
end
