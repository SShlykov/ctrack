# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ctrack,
  ecto_repos: [Ctrack.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  version: "1.0.0",
  name: "Ctrack",
  tbank_token: System.get_env("TToken"),
  instruments: [
    %{
      figi: "BBG004730RP0",
      instrumentId: "c7c26356-7352-4c37-8316-b1d93b18e16e",
      name: "Газпром"
    },
    %{
      figi: "TCS80A107UL4",
      instrumentId: "87db07bc-0e02-4e29-90bb-05e8ef791d7b",
      name: "Т-Технологии"
    },
    %{
      figi: "TCS00A107T19",
      instrumentId: "7de75794-a27f-4d81-a39b-492345813822",
      name: "Яндекс"
    }
  ]

# Configures the endpoint
config :ctrack, CtrackWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CtrackWeb.ErrorHTML, json: CtrackWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Ctrack.PubSub,
  live_view: [signing_salt: "0yU9cE7S"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ctrack, Ctrack.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ctrack: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ctrack: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
