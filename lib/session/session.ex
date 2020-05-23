defmodule James.Session.State do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field(:chat_id, pos_integer(), enforce: true)
    field(:timer, reference(), enforce: true)
    field(:conn, Mint.Http.t(), enforce: true)
  end

  def new(chat_id, conn, timer) do
    %State{chat_id: chat_id, conn: conn, timer: timer}
  end
end

defmodule James.Session do
  use GenServer

  alias __MODULE__.State
  alias __MODULE__.Registry

  require Logger

  def start_link(chat_id) do
    GenServer.start_link(__MODULE__, [chat_id])
  end

  def init([chat_id]) do
    {:ok, conn} = connect()
    {:ok, State.new(chat_id, conn, set_timer())}
  end

  defp connect() do
    {:ok, scheme} = Confex.fetch_env(:james, :api_scheme)
    {:ok, host} = Confex.fetch_env(:james, :api_host)
    {:ok, port} = Confex.fetch_env(:james, :api_port)

    {:ok, _conn} = Mint.HTTP.connect(scheme, host, port)
  end

  def respond(chat_id, msg) do
    {:ok, pid} = Registry.get_session(chat_id)
    :ok = GenServer.call(pid, {:send, msg})
  end

  def handle_call({:send, msg}, _from, state) do
    body = %{"chat_id" => state.chat_id, "text" => msg} |> Jason.encode!()

    {:ok, new_conn, _req_ref} =
      Mint.HTTP.request(
        state.conn,
        "POST",
        url_path("/sendMessage"),
        [
          {"Content-Type", "application/json"}
        ],
        body
      )

    new_state = %State{state | conn: new_conn}
    {:reply, :ok, update_timer(new_state)}
  end

  def handle_info({:ssl, _sock, _data} = msg, state) do
    {:ok, new_conn, resp} = Mint.HTTP.stream(state.conn, msg)
    {:ok, data} = get_resp_data(resp)
    Logger.debug("Received response: #{inspect(data)}")
    {:noreply, %State{state | conn: new_conn}}
  end

  def handle_info({:ssl_closed, _}, state) do
    Logger.warn("Connection closed. Restarting")
    {:ok, new_conn} = connect()
    {:noreply, %State{state | conn: new_conn}}
  end

  def handle_info(:timeout, state) do
    Logger.debug("Terminating session by timeout")
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Received info message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp url_path(path) do
    {:ok, api_token} = Confex.fetch_env(:james, :api_token)
    "/bot#{api_token}#{path}"
  end

  defp get_resp_data(resp) do
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

  defp set_timer() do
    {:ok, session_timeout} = Confex.fetch_env(:james, :session_timeout)
    Process.send_after(self(), :timeout, session_timeout)
  end

  def update_timer(state) do
    Process.cancel_timer(state.timer)
    %State{state | timer: set_timer()}
  end

  def child_spec(chat_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [chat_id]},
      restart: :temporary
    }
  end
end
