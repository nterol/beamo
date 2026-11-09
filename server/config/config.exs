# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :beamo,
  ecto_repos: [Beamo.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure the endpoint
config :beamo, BeamoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: BeamoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Beamo.PubSub,
  live_view: [signing_salt: "/LWmdgrz"]

config :beamo, Oban,
  engine: Oban.Engines.Basic,
  repo: Beamo.Repo,
  queues: [default: 10, push: 20],
  plugins: [{Oban.Plugins.Pruner, max_age: 7 * 24 * 60 * 60}]

config :beamo, :otp_provider, Beamo.Accounts.OTP.Fake

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
