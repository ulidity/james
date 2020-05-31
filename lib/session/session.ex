defmodule James.Session.Context do
  use TypedStruct

  alias __MODULE__
  alias James.Reminder

  typedstruct do
    field(:chat_id, pos_integer(), enforce: true)
    field(:conn, Mint.Http.t(), enforce: true)
    field(:timeout, pos_integer(), enforce: true)
    field(:reminder, Reminder.t(), enforce: true)
  end

  def new(chat_id, conn) do
    {:ok, timeout} = Confex.fetch_env(:james, :session_timeout)

    %Context{chat_id: chat_id, conn: conn, timeout: timeout, reminder: Reminder.empty()}
  end
end

defmodule James.Session do
  use GenStateMachine

  alias __MODULE__.Context
  alias __MODULE__.Registry

  alias James.Text
  alias James.Reminder

  require Logger

  @state_awaiting_command :awaiting_command
  @state_awaiting_reminder_title :awaiting_reminder_title
  @state_awaiting_reminder_timeout :awaiting_reminder_timeout

  @command_new "/new"

  @timeout_regex ~r/^\s*((?<days>\d+)[dD])?\s*((?<hours>\d+)[hH])?\s*((?<minutes>\d+)[mM])?\s*((?<seconds>\d+)[sS])?$/

  def start_link(chat_id) do
    GenStateMachine.start_link(__MODULE__, [chat_id])
  end

  def init([chat_id]) do
    {:ok, conn} = connect()
    context = Context.new(chat_id, conn)
    {:ok, @state_awaiting_command, context, context.timeout}
  end

  def handle_event(:cast, {:process_message, msg, lang}, @state_awaiting_command = state, context) do
    case command?(msg) do
      true ->
        {:ok, next_state, reply_msg} = process_command(msg)
        :ok = send_message(:internal, self(), reply_msg, lang)
        {:next_state, next_state, %Context{context | reminder: Reminder.empty()}}

      false ->
        :ok = send_message(:internal, self(), "NOT_A_COMMAND", lang)
        {:next_state, state, %Context{context | reminder: Reminder.empty()}}
    end
  end

  def handle_event(
        :cast,
        {:process_message, msg, lang},
        @state_awaiting_reminder_title,
        context
      ) do
    case command?(msg) do
      true ->
        {:ok, next_state, reply_msg} = process_command(msg)
        :ok = send_message(:internal, self(), reply_msg, lang)
        {:next_state, next_state, %Context{context | reminder: Reminder.empty()}}

      false ->
        :ok = send_message(:internal, self(), "ENTER_REMINDER_TIMEOUT", lang)
        updated_reminder = Reminder.with_title(context.reminder, msg)

        {:next_state, @state_awaiting_reminder_timeout,
         %Context{context | reminder: updated_reminder}}
    end
  end

  def handle_event(
        :cast,
        {:process_message, msg, lang},
        @state_awaiting_reminder_timeout = state,
        context
      ) do
    case command?(msg) do
      true ->
        {:ok, next_state, reply_msg} = process_command(msg)
        :ok = send_message(:internal, self(), reply_msg, lang)
        {:next_state, next_state, %Context{context | reminder: Reminder.empty()}}

      false ->
        case get_timeout(msg) do
          {:ok, timeout} ->
            :ok = send_message(:internal, self(), "REMINDER_CREATED", lang)
            updated_reminder = Reminder.with_timeout(context.reminder, timeout)
            :ok = Reminder.Storage.set_reminder(updated_reminder, context.chat_id)
            {:next_state, @state_awaiting_command, %Context{context | reminder: Reminder.empty()}}

          :error ->
            :ok = send_message(:internal, self(), "INVALID_REMINDER_TIMEOUT", lang)
            {:next_state, state, context}
        end
    end
  end

  def handle_event(:cast, {:send_message, msg, lang}, state, context) do
    {:ok, new_conn} = do_send_message(context.conn, context.chat_id, msg, lang)
    {:next_state, state, %Context{context | conn: new_conn}}
  end

  def handle_event(:info, {:ssl, _sock, _data} = msg, state, context) do
    {:ok, new_conn, resp} = Mint.HTTP.stream(context.conn, msg)
    {:ok, resp_body} = get_resp_body(resp)
    Logger.debug("Received response: #{inspect(resp_body)}")
    {:next_state, state, %Context{context | conn: new_conn}}
  end

  def handle_event(:info, {:ssl_closed, _}, state, context) do
    Logger.warn("Connection closed. Restarting")
    {:ok, new_conn} = connect()
    {:next_state, state, %Context{context | conn: new_conn}}
  end

  def handle_event(:timeout, _event, state, context) do
    Logger.warn("Session for chat #{context.chat_id} expired. State: #{state}")
    {:stop, :normal, context}
  end

  defp connect() do
    {:ok, scheme} = Confex.fetch_env(:james, :api_scheme)
    {:ok, host} = Confex.fetch_env(:james, :api_host)
    {:ok, port} = Confex.fetch_env(:james, :api_port)

    {:ok, _conn} = Mint.HTTP.connect(scheme, host, port)
  end

  def process_message(chat_id, msg, lang) do
    {:ok, pid} = Registry.get_session(chat_id)
    :ok = GenStateMachine.cast(pid, {:process_message, msg, lang})
  end

  def send_message(:external, chat_id, msg, lang) do
    {:ok, pid} = Registry.get_session(chat_id)
    :ok = GenStateMachine.cast(pid, {:send_message, msg, lang})
  end

  def send_message(:internal, pid, msg, lang) do
    :ok = GenStateMachine.cast(pid, {:send_message, msg, lang})
  end

  defp do_send_message(conn, chat_id, msg, lang) do
    {:ok, msg} = Text.message(msg, lang)

    body = %{"chat_id" => chat_id, "text" => msg} |> Jason.encode!()

    {:ok, new_conn, _req_ref} =
      Mint.HTTP.request(
        conn,
        "POST",
        url_path("/sendMessage"),
        [
          {"Content-Type", "application/json"}
        ],
        body
      )

    {:ok, new_conn}
  end

  defp url_path(path) do
    {:ok, api_token} = Confex.fetch_env(:james, :api_token)
    "/bot#{api_token}#{path}"
  end

  defp get_resp_body(resp) do
    data =
      resp
      |> Enum.filter(fn
        {:data, _req_ref, _data} -> true
        _ -> false
      end)
      |> Enum.map(fn {:data, _req_ref, data} ->
        data
      end)
      |> Enum.reduce("", fn chunk, data ->
        "#{data}#{chunk}"
      end)
      |> Jason.decode!()

    {:ok, data}
  end

  defp process_command(@command_new) do
    {:ok, @state_awaiting_reminder_title, "ENTER_REMINDER_TITLE"}
  end

  def command?(@command_new), do: true
  def command?(_), do: false

  defp get_timeout(msg) do
    case Regex.named_captures(@timeout_regex, msg) do
      nil ->
        :error

      captures when map_size(captures) == 0 ->
        :error

      captures ->
        Logger.debug("Captured time #{inspect(captures)}")

        days_seconds = get_capture_value(captures, "days") * 60 * 60 * 24
        hours_seconds = get_capture_value(captures, "hours") * 60 * 60
        minutes_seconds = get_capture_value(captures, "minutes") * 60
        seconds = get_capture_value(captures, "seconds")

        total_seconds = days_seconds + hours_seconds + minutes_seconds + seconds

        case total_seconds <= 0 do
          true -> :error
          false -> {:ok, total_seconds}
        end
    end
  end

  defp get_capture_value(captures, capture_name) do
    case Map.get(captures, capture_name, "0") do
      "" -> 0
      "0" -> 0
      n -> String.to_integer(n)
    end
  end

  def terminate(_reason, _state, context) do
    {:ok, _conn} = Mint.HTTP.close(context.conn)
  end

  def child_spec(chat_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [chat_id]},
      restart: :temporary
    }
  end
end
