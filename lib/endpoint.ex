defmodule James.Endpoint do
  use Plug.Router

  alias James.Message

  require Logger

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  post "/notify" do
    Message.process(conn.body_params)
    send_resp(conn, 200, "ok")
  end
end
