use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# GroupherServerWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :groupher_server, GroupherServerWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "groupher.com", port: 80]

# cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
# config :logger, level: :info
config :logger, :console, format: "[$level] $message\n"

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :groupher_server, GroupherServerWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :groupher_server, GroupherServerWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :groupher_server, GroupherServerWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
# import_config "prod.secret.exs"

config :groupher_server, GroupherServerWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :groupher_server, Helper.Guardian,
  issuer: "groupher_server",
  secret_key: System.get_env("GUARDIAN_KEY")

# You can generate a new secret by running:
# mix phx.gen.secret
# should use RDS 内网地址
config :groupher_server, GroupherServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME" || "cps_server_prod"),
  hostname: System.get_env("DB_HOST"),
  port: String.to_integer(System.get_env("DB_PORT") || "3433"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE") || "20")

config :groupher_server, :github_oauth,
  client_id: System.get_env("OAUTH_GITHUB_CLIENT_ID"),
  client_secret: System.get_env("OAUTH_GITHUB_CLIENT_SECRET"),
  redirect_uri: System.get_env("OAUTH_GITHUB_REDIRECT_URI")

config :groupher_server, :ip_locate, ip_service: System.get_env("IP_LOCATE_KEY")
config :groupher_server, :plausible, token: System.get_env("PLAUSIBLE_TOKEN")
config :groupher_server, :audit, token: System.get_env("AUDIT_TOKEN")

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production"
  },
  included_environments: [:prod]

#  config email services
config :groupher_server, GroupherServer.Mailer, api_key: System.get_env("MAILER_API_KEY")
