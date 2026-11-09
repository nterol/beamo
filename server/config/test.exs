import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :beamo, Beamo.Repo,
  username: "beamo",
  password: "beamo",
  hostname: "localhost",
  port: 5434,
  database: "beamo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :beamo, BeamoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GxZ1wI8D4OxUMndAUBC/Y3E6o5P6Xe/uNewLDXilHlJEaojbkz604/38akYTqpkW",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :beamo, Oban, testing: :manual

config :beamo, :expo_req_options, plug: {Req.Test, Beamo.Push.Expo}
config :beamo, :prelude_req_options, plug: {Req.Test, Beamo.Accounts.OTP.Prelude}
config :beamo, :prelude_api_key, "test-key"
