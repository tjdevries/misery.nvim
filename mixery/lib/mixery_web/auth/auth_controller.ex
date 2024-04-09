defmodule MixeryWeb.Auth.AuthController do
  use MixeryWeb, :controller

  @doc """
  Redirect to the OAuth2 provider's authorization URL.
  """
  def request(conn, _params) do
    client = twitch_client()
    authorize_url = OAuth2.Client.authorize_url!(client)
    redirect(conn, external: authorize_url)
  end

  @doc """
  Callback to handle the provider's redirect back with the code for access
  token.
  """
  def callback(conn, %{"code" => code}) do
    client = twitch_client()

    twitch_token_params = %{
      client_id: client.client_id,
      client_secret: client.client_secret,
      code: code,
      grant_type: "authorization_code",
      redirect_uri: client.redirect_uri
    }

    client =
      client
      |> OAuth2.Client.merge_params(twitch_token_params)
      |> OAuth2.Client.get_token!()

    %{body: %{"data" => [user_data]}} =
      client
      |> OAuth2.Client.put_header("client-id", client.client_id)
      |> OAuth2.Client.get!("/helix/users")

    user_data =
      user_attrs(user_data)
      |> IO.inspect(label: "TWITCH USER")

    Mixery.Twitch.upsert_user(user_data["twitch_id"], %{
      login: user_data["login"],
      display: user_data["display_name"]
    })

    conn
    |> MixeryWeb.TwitchAuth.log_in_twitch(user_data)
    |> redirect(to: ~p"/game")
  end

  # Build the Twitch OAuth2 client.
  defp twitch_client do
    # url = MixeryWeb.Endpoint.url()
    # TODO: ????? how to test local and let people do remote??? :)
    url = "https://rewards.teej.tv"
    config = Application.fetch_env!(:mixery, :event_sub)

    client_id =
      Keyword.fetch!(config, :client_id) || raise "TWITCH_CLIENT_ID not set"

    client_secret =
      Keyword.fetch!(config, :client_secret) || raise "TWITCH_CLIENT_SECRET not set"

    OAuth2.Client.new(
      # default
      strategy: OAuth2.Strategy.AuthCode,
      client_id: client_id,
      client_secret: client_secret,
      site: "https://api.twitch.tv",
      authorize_url: "https://id.twitch.tv/oauth2/authorize",
      redirect_uri: "#{url}/auth/twitch/callback",
      token_url: "https://id.twitch.tv/oauth2/token",
      token_method: :post,
      serializers: %{"application/json" => Jason}
    )
  end

  defp user_attrs(user_data) do
    %{"display_name" => display_name, "login" => login, "id" => id} = user_data

    %{
      "login" => login,
      "display_name" => display_name,
      "twitch_id" => id
    }
  end
end
