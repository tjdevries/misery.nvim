# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mixery,
  ecto_repos: [Mixery.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :mixery, MixeryWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MixeryWeb.ErrorHTML, json: MixeryWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mixery.PubSub,
  live_view: [signing_salt: "4iXwRDmM"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :mixery, Mixery.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  mixery: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# config :logger,
#   handle_otp_reports: true,
#   handle_sasl_reports: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :mixery, Mixery.Repo,
  database: "mixery",
  username: "tjdevries",
  password: "password",
  hostname: "localhost"

# migration_primary_key: [type: :string],
# migration_foreign_key: [type: :string]

config :mixery, Oban,
  plugins: [{Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 14}],
  queues: [default: 10, twitch: 1],
  repo: Mixery.Repo

config :nx, default_backend: EXLA.Backend
