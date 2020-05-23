defmodule James.Event.Machine.State do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field(:conn, pid(), enforce: true)
    field(:pubsub, pid(), enforce: true)
  end

  def new(conn, pubsub) do
    %State{conn: conn, pubsub: pubsub}
  end
end

defmodule James.Event.Machine do
  use GenServer

  alias __MODULE__.State

  require Logger

  @events_channel "__keyevent*__:expired"

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, conn} = connect()
    {:ok, pubsub} = subscribe()

    {:ok, State.new(conn, pubsub)}
  end

  def set_timer(event, timeout) do
    :ok = GenServer.call(__MODULE__, {:set_timer, event, timeout})
  end

  def handle_call({:set_timer, event, timeout}, _from, state) do
    do_set_timer(state.conn, event, timeout)
    {:reply, :ok, state}
  end

  def handle_info({:redix_pubsub, pubsub, _ref, :pmessage, %{payload: event_id}}, state) do
    Logger.info("Event #{inspect(event_id)} fired")
    {:ok, event} = get_event(state.conn, event_id)
    Logger.debug("Event #{inspect(event)} retreived")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Received message #{inspect(msg)}")
    {:noreply, state}
  end

  defp do_set_timer(conn, event, timeout) do
    event_id = Ulid.generate()

    Logger.debug("Setting #{timeout} seconds timer for event #{event_id}")

    {:ok, "OK"} = Redix.command(conn, ["SET", "#{event_id}:event", event])
    {:ok, "OK"} = Redix.command(conn, ["SETEX", event_id, timeout, ""])
  end

  defp get_event(conn, event_id) do
    {:ok, _event} = Redix.command(conn, ["GET", "#{event_id}:event"])
  end

  defp connect() do
    {:ok, db_host} = Confex.fetch_env(:james, :db_host)
    {:ok, db_port} = Confex.fetch_env(:james, :db_port)

    Logger.info("Connecting to db at #{db_host}:#{db_port}")

    {:ok, _conn} = Redix.start_link(host: db_host, port: db_port)
  end

  defp subscribe() do
    {:ok, db_host} = Confex.fetch_env(:james, :db_host)
    {:ok, db_port} = Confex.fetch_env(:james, :db_port)

    Logger.info("Subscribing to db events at #{db_host}:#{db_port}")

    {:ok, pubsub} = Redix.PubSub.start_link(host: db_host, port: db_port)

    {:ok, ref} = Redix.PubSub.psubscribe(pubsub, @events_channel, self())

    receive do
      {
        :redix_pubsub,
        ^pubsub,
        ^ref,
        :psubscribed,
        %{pattern: @events_channel}
      } ->
        Logger.info("Successfully subscribed to db events")
        {:ok, pubsub}
    after
      5_000 ->
        Logger.error("Subscribe attempt failed")
        Process.exit(self(), :failed_to_subscribe)
    end
  end
end
