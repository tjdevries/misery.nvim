defmodule Mixery.MixProject do
  use Mix.Project

  def project do
    [
      app: :mixery,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Mixery.Application, []},
      extra_applications: [:logger, :runtime_tools, :wx, :observer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.2"},
      {:hello_twitch_eventsub,
       git: "https://github.com/hellostream/twitch_eventsub", branch: "main"},
      {:hello_twitch_api,
       git: "https://github.com/hellostream/twitch_api", branch: "main", override: true},
      {:dotenv, "~> 3.0.0"},

      # Oban
      {:oban, "~> 2.17"},

      # Auth related
      {:oauth2, "~> 2.0"},

      # Chat said this one was amazing and i'll have literally zero issues
      # {:mint_web_socket, "~> 1.0.0"},
      # RyanWinchester_TV: said this one was amazing and way better than anything he could write (duh, talk about being redundant)
      {:fresh, "~> 0.4.3"},
      {:websockex, "~> 0.4.3"},
      # Audio shenanigans
      {:membrane_core, "~> 1.0"},
      {:membrane_hackney_plugin, "~> 0.11.0"},
      {:membrane_mp3_mad_plugin, "~> 0.18.3"},
      {:membrane_portaudio_plugin, "~> 0.19.2"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild mixery"],
      "assets.deploy": [
        "esbuild mixery --minify",
        "phx.digest"
      ]
    ]
  end
end
