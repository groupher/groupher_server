defmodule GroupherServerWeb.Endpoint do
  # use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :groupher_server

  socket("/socket", GroupherServerWeb.UserSocket)

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  # plug(Sentry.PlugContext)
  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # plug(:inspect_conn)

  plug(
    Corsica,
    # log: [rejected: :error],
    log: [rejected: :debug],
    origins: [
      "http://localhost:3000",
      "http://localhost:3001",
      ~r{^https://(.*\.?)groupher\.com$}
    ],
    # origins: "*",
    allow_headers: [
      "authorization",
      "content-type",
      "special",
      "accept",
      "origin",
      "x-requested-with"
    ],
    allow_credentials: true,
    max_age: 600
  )

  plug(GroupherServerWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  # def init(_key, config) do
  #   if config[:load_from_system_env] do
  #     {:ok,
  #      Keyword.put(config, :http, [:inet6, ip: {0, 0, 0, 0}, port: System.get_env("PORT") || 8080])}
  #   else
  #     {:ok, config}
  #   end
  # end
end
