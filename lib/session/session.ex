defmodule James.Session.Context do
  use TypedStruct

  alias __MODULE__
  alias James.Reminder

  typedstruct do
    field(:chat_id, pos_integer(), enforce: true)
    field(:conn, Mint.Http.t(), enforce: true)
    field(:reminder, Reminder.t())
    field(:timer, reference())
  end

  def new(chat_id, conn) do
    %Context{chat_id: chat_id, conn: conn}
  end
end

defmodule James.Session do
  use GenStateMachine

  alias __MODULE__.Context
  alias __MODULE__.Registry

  alias James.Text
  alias James.Reminder

  require Logger

  @parse_mode "MarkdownV2"

  @state_awaiting_command :awaiting_command
  @state_awaiting_reminder_title :awaiting_reminder_title
  @state_awaiting_reminder_timeout :awaiting_reminder_timeout

  @command_start "/start"
  @command_new "/new"
  @command_cancel "/cancel"

  @applicable_commands %{
    @state_awaiting_command => [@command_new, @command_start],
    @state_awaiting_reminder_title => [@command_new, @command_cancel],
    @state_awaiting_reminder_timeout => [@command_new, @command_cancel]
  }

  @timeout_regex ~r/^\s*((?<days>\d+)[dD])?\s*((?<hours>\d+)[hH])?\s*((?<minutes>\d+)[mM])?\s*((?<seconds>\d+)[sS])?$/

  def start_link(chat_id) do
    GenStateMachine.start_link(__MODULE__, [chat_id])
  end

  def init([chat_id]) do
    {:ok, conn} = connect()
    context = Context.new(chat_id, conn)
    {:ok, @state_awaiting_command, set_timer(context)}
  end

  def handle_event(:cast, {:process_message, msg, lang}, @state_awaiting_command = state, context) do
    case command?(msg) do
      true ->
        case process_command(msg, state) do
          {:ok, next_state, reply_msg} ->
            :ok = send_message(:internal, self(), reply_msg, lang)
            new_context = %Context{context | reminder: Reminder.empty()}
            {:next_state, next_state, set_timer(new_context)}

          {:error, :not_applicable} ->
            :ok = send_message(:internal, self(), James.Text.Codes.command_not_applicable(), lang)
            {:next_state, state, set_timer(context)}
        end

      false ->
        :ok = send_message(:internal, self(), James.Text.Codes.invalid_command(), lang)
        new_context = %Context{context | reminder: Reminder.empty()}
        {:next_state, state, set_timer(new_context)}
    end
  end

  def handle_event(
        :cast,
        {:process_message, msg, lang},
        @state_awaiting_reminder_title = state,
        context
      ) do
    case command?(msg) do
      true ->
        case process_command(msg, state) do
          {:ok, next_state, reply_msg} ->
            :ok = send_message(:internal, self(), reply_msg, lang)
            new_context = %Context{context | reminder: Reminder.empty()}
            {:next_state, next_state, set_timer(new_context)}

          {:error, :not_applicable} ->
            :ok = send_message(:internal, self(), James.Text.Codes.command_not_applicable(), lang)
            {:next_state, state, set_timer(context)}
        end

      false ->
        :ok = send_message(:internal, self(), James.Text.Codes.enter_reminder_timeout(), lang)
        updated_reminder = Reminder.with_title(context.reminder, msg)
        new_context = %Context{context | reminder: updated_reminder}
        {:next_state, @state_awaiting_reminder_timeout, set_timer(new_context)}
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
        case process_command(msg, state) do
          {:ok, next_state, reply_msg} ->
            :ok = send_message(:internal, self(), reply_msg, lang)
            new_context = %Context{context | reminder: Reminder.empty()}
            {:next_state, next_state, set_timer(new_context)}

          {:error, :not_applicable} ->
            :ok = send_message(:internal, self(), James.Text.Codes.command_not_applicable(), lang)
            {:next_state, state, set_timer(context)}
        end

      false ->
        case get_timeout(msg) do
          {:ok, timeout} ->
            :ok = send_message(:internal, self(), James.Text.Codes.reminder_created(), lang)
            updated_reminder = Reminder.with_timeout(context.reminder, timeout)
            :ok = Reminder.Storage.set_reminder(updated_reminder, context.chat_id, lang)
            {:next_state, @state_awaiting_command, %Context{context | reminder: Reminder.empty()}}

          :error ->
            :ok =
              send_message(:internal, self(), James.Text.Codes.invalid_reminder_timeout(), lang)

            {:next_state, state, set_timer(context)}
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

  def handle_event(:info, :timeout, state, context) do
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

    body =
      %{
        "chat_id" => chat_id,
        "text" => msg,
        "parse_mode" => @parse_mode
      }
      |> Jason.encode!()

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

  defp process_command(@command_start = command, state) do
    if command in @applicable_commands[state] do
      {:ok, @state_awaiting_command, James.Text.Codes.welcome()}
    else
      {:error, :not_applicable}
    end
  end

  defp process_command(@command_new = command, state) do
    if command in @applicable_commands[state] do
      {:ok, @state_awaiting_reminder_title, James.Text.Codes.enter_reminder_title()}
    else
      {:error, :not_applicable}
    end
  end

  defp process_command(@command_cancel = command, state) do
    if command in @applicable_commands[state] do
      {:ok, @state_awaiting_command, James.Text.Codes.command_canceled()}
    else
      {:error, :not_applicable}
    end
  end

  def command?(@command_start), do: true
  def command?(@command_new), do: true
  def command?(@command_cancel), do: true
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

  def set_timer(context) do
    {:ok, timeout} = Confex.fetch_env(:james, :session_timeout)

    unless context.timer == nil do
      Process.cancel_timer(context.timer)
    end

    timer = Process.send_after(self(), :timeout, timeout)

    %Context{context | timer: timer}
  end

  def child_spec(chat_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [chat_id]},
      restart: :temporary
    }
  end
end
