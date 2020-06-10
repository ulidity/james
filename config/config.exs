use Mix.Config

config :logger,
  backends: [:console]

config :logger, :console,
  level: :debug,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:pid]

config :james,
  api_scheme: {:system, :atom, "JAMES_API_SCHEME", :https},
  api_host: {:system, :string, "JAMES_API_HOST", "api.telegram.org"},
  api_port: {:system, :integer, "JAMES_API_PORT", 443},
  api_token: {:system, :string, "JAMES_API_TOKEN"},
  http_port: {:system, :integer, "JAMES_HTTP_PORT", 80},
  session_timeout: {:system, :integer, "JAMES_SESSION_TIMEOUT", 60_000},
  db_host: {:system, :string, "JAMES_DB_HOST"},
  db_port: {:system, :integer, "JAMES_DB_PORT"},
  reminder_retrigger_interval: {:system, :integer, "JAMES_REMINDER_RETRIGGER_INTERVAL", 60}
