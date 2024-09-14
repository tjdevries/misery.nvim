defmodule MixeryWeb.Router do
  use MixeryWeb, :router

  import MixeryWeb.TwitchAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MixeryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug :fetch_current_twitch
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MixeryWeb do
    live "/", IndexLive
  end

  scope "/", MixeryWeb do
    pipe_through :browser

    # get "/", PageController, :home
    live "/leaderboard", LeaderboardLive
  end

  pipeline :overlay do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MixeryWeb.Layouts, :overlay}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug MixeryWeb.Plugs.Secret
  end

  scope "/", MixeryWeb do
    pipe_through :overlay

    live "/overlay", OverlayLive
  end

  pipeline :teej do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MixeryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug MixeryWeb.Plugs.Teej
  end

  scope "/", MixeryWeb do
    pipe_through :teej

    live "/events", EventLive
    live "/overlay-web", OverlayLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", MixeryWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  # if Application.compile_env(:mixery, :dev_routes) do
  #   # If you want to use the LiveDashboard in production, you should put
  #   # it behind authentication and allow only admins to access it.
  #   # If your application does not have an admins-only section yet,
  #   # you can use Plug.BasicAuth to set up some basic authentication
  #   # as long as you are also using SSL (which you should anyway).
  #   import Phoenix.LiveDashboard.Router
  #
  #   scope "/dev" do
  #     pipe_through :browser
  #
  #     live_dashboard "/dashboard", metrics: MixeryWeb.Telemetry
  #     forward "/mailbox", Plug.Swoosh.MailboxPreview
  #   end
  # end

  ## Authentication routes
  #
  # import Plug.BasicAuth
  # pipeline :mixery_dev do
  #   plug :basic_auth, username: "teej_dv", password: "password"
  # end

  scope "/auth", MixeryWeb.Auth do
    pipe_through [:browser, :redirect_if_twitch_is_authenticated]

    get "/twitch", AuthController, :request
    get "/twitch/callback", AuthController, :callback

    live_session :redirect_if_twitch_is_authenticated,
      on_mount: [{MixeryWeb.TwitchAuth, :redirect_if_twitch_is_authenticated}] do
      live "/twitch/login", TwitchLoginLive, :new
    end
  end

  scope "/", MixeryWeb do
    pipe_through [:browser, :require_authenticated_twitch]

    live_session :require_authenticated_twitch,
      on_mount: [{MixeryWeb.TwitchAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive, :index

      # live "/twitch_accounts/settings", TwitchSettingsLive, :edit
    end
  end

  # scope "/", MixeryWeb do
  #   pipe_through [:browser, :redirect_if_twitch_is_authenticated]
  #
  #   live_session :redirect_if_twitch_is_authenticated,
  #     on_mount: [{MixeryWeb.TwitchAuth, :redirect_if_twitch_is_authenticated}] do
  #     live "/login", TwitchLoginLive, :new
  #   end
  #
  #   post "/login", TwitchSessionController, :create
  # end

  # scope "/", MixeryWeb do
  #   pipe_through [:browser]
  #
  #   get "/logout", TwitchAuth, :delete
  #
  #   # delete "/logout", TwitchSessionController, :delete
  # end
end
