import Config

config :groupher_server, GroupherServerWeb.Endpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :groupher_server, Helper.Guardian,
  issuer: "groupher_server",
  secret_key: "hello"

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

# Configure your database
config :groupher_server, GroupherServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "groupher_server_mock",
  hostname: "localhost",
  pool_size: 50,
  queue_target: 5000

#  config email services
config :groupher_server, GroupherServer.Mailer, adapter: Bamboo.LocalAdapter

config :ex_aliyun_openapi, :sts,
  access_key_id: System.get_env("ALI_OSS_STS_AK"),
  access_key_secret: System.get_env("_ALIOSS_STS_AS")

config :groupher_server, Helper.OSS,
  endpoint: "oss-cn-shanghai.aliyuncs.com",
  access_key_id: System.get_env("ALI_OSS_STS_AK"),
  access_key_secret: System.get_env("_ALIOSS_STS_AS")
