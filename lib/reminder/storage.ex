defmodule James.Reminder.Storage.State do
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

defmodule James.Reminder.Storage do
  use GenServer

  alias __MODULE__.State
  alias James.Session

  require Logger

  @events_channel "__keyevent*__:expired"

  @key_reminder "reminder"
  @key_chat_id "chat_id"
  @key_lang "lang"

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, conn} = connect()
    {:ok, pubsub} = subscribe()

    {:ok, State.new(conn, pubsub)}
  end

  def set_reminder(reminder, chat_id, lang) do
    GenServer.call(__MODULE__, {:set_reminder, reminder, chat_id, lang})
  end

  def remove_reminder(id) do
    GenServer.call(__MODULE__, {:remove_reminder, id})
  end

  def handle_call({:set_reminder, reminder, chat_id, lang}, _from, state) do
    do_set_reminder(state.conn, reminder, chat_id, lang)
    {:reply, :ok, state}
  end

  def handle_call({:remove_reminder, id}, _from, state) do
    case do_remove_reminder(state.conn, id) do
      :ok ->
        {:reply, :ok, state}

      {:error, _error} = error ->
        {:reply, error, state}
    end
  end

  def handle_info({:redix_pubsub, _pubsub, _ref, :pmessage, %{payload: id}}, state) do
    Logger.info("Reminder #{inspect(id)} fired")
    {:ok, reminder, chat_id, lang} = get_reminder(state.conn, id)
    Logger.debug("Rimnder #{reminder} for chat #{chat_id} retreived")

    :ok =
      Session.send_message(
        :external,
        chat_id,
        {James.Text.Codes.reminder(), [reminder: reminder]},
        lang,
        [{:confirm_reminder_completion, [id: id, lang: lang]}]
      )

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Received message #{inspect(msg)}")
    {:noreply, state}
  end

  defp do_set_reminder(conn, reminder, chat_id, lang) do
    id = Ulid.generate()

    Logger.debug("Setting reminder #{reminder.title} for #{reminder.timeout} seconds. ID: #{id}")

    {:ok, "OK"} = Redix.command(conn, ["SET", "#{id}:#{@key_reminder}", reminder.title])
    {:ok, "OK"} = Redix.command(conn, ["SET", "#{id}:#{@key_chat_id}", chat_id])
    {:ok, "OK"} = Redix.command(conn, ["SET", "#{id}:#{@key_lang}", lang])
    {:ok, "OK"} = Redix.command(conn, ["SETEX", id, reminder.timeout, ""])
  end

  defp get_reminder(conn, id) do
    {:ok, reminder} = Redix.command(conn, ["GET", "#{id}:#{@key_reminder}"])
    {:ok, chat_id} = Redix.command(conn, ["GET", "#{id}:#{@key_chat_id}"])
    {:ok, lang} = Redix.command(conn, ["GET", "#{id}:#{@key_lang}"])

    {:ok, reminder, chat_id, lang}
  end

  defp do_remove_reminder(conn, id) do
    case Redix.command(conn, ["DEL", id]) do
      {:ok, 1} ->
        {:ok, 1} = Redix.command(conn, ["DEL", "#{id}:#{@key_reminder}"])
        {:ok, 1} = Redix.command(conn, ["DEL", "#{id}:#{@key_chat_id}"])
        {:ok, 1} = Redix.command(conn, ["DEL", "#{id}:#{@key_lang}"])

        :ok

      {:ok, 0} ->
        {:error, :not_found}
    end
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
