# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :pears, Pears.Repo,
  ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2")

config :pears, PearsWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE"),
  server: true

config :timber,
  api_key: Map.fetch!(System.get_env(), "TIMBER_KEY"),
  source_id: Map.fetch!(System.get_env(), "TIMBER_SOURCE_ID")

config :opentelemetry,
  processors: [
    otel_batch_processor: %{
      exporter:
        {OpenTelemetry.Honeycomb.Exporter,
         write_key: Map.fetch!(System.get_env(), "HONEYCOMB_KEY"), dataset: "pears"}
    }
  ]

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :pears, PearsWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
