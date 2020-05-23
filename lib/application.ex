defmodule James.Application do
  use Application

  def start(_type, _args) do
    {:ok, port} = Confex.fetch_env(:james, :http_port)

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: James.Endpoint,
        options: [port: port]
      ),
      {DynamicSupervisor,
       [
         strategy: :one_for_one,
         name: James.Session.Supervisor
       ]},
      {Task.Supervisor,
       [
         name: James.Message.Processor
       ]},
      {James.Session.Registry, []},
      {James.Event.Machine, []}
    ]

    opts = [strategy: :one_for_one, name: James.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
