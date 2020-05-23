defmodule James.Session.Registry.State do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field(:pid_mapping, map(), enforce: true)
    field(:chat_mapping, map(), enforce: true)
  end

  def new() do
    %State{pid_mapping: %{}, chat_mapping: %{}}
  end

  def new(pid_mapping, chat_mapping) do
    %State{pid_mapping: pid_mapping, chat_mapping: chat_mapping}
  end
end

defmodule James.Session.Registry do
  use GenServer

  alias __MODULE__.State
  alias James.Session.Supervisor, as: SessionSupervisor

  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, State.new()}
  end

  def get_session(chat_id) do
    {:ok, _pid} = GenServer.call(__MODULE__, {:get_session, chat_id})
  end

  def handle_call({:get_session, chat_id}, _from, state) do
    {:ok, pid, new_state} =
      case Map.fetch(state.chat_mapping, chat_id) do
        {:ok, pid} ->
          case pid in Map.keys(state.pid_mapping) && Process.alive?(pid) do
            true ->
              {:ok, pid, state}

            false ->
              new_pid_mapping = Map.delete(state.pid_mapping, pid)
              new_chat_mapping = Map.delete(state.chat_mapping, chat_id)
              new_state = State.new(new_pid_mapping, new_chat_mapping)

              {:ok, _pid, _state} = start_session(chat_id, new_state)
          end

        :error ->
          {:ok, _pid, _state} = start_session(chat_id, state)
      end

    {:reply, {:ok, pid}, new_state}
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
    Logger.info("Session #{inspect(pid)} terminated normally")
    {chat_id, new_pid_mapping} = Map.pop(state.pid_mapping, pid)
    new_chat_mapping = Map.delete(state.chat_mapping, chat_id)
    {:noreply, State.new(new_pid_mapping, new_chat_mapping)}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.error("Session #{inspect(pid)} terminated unexpectedely. Reason: #{inspect(reason)}")
    {chat_id, new_pid_mapping} = Map.pop(state.pid_mapping, pid)
    new_chat_mapping = Map.delete(state.chat_mapping, chat_id)
    {:noreply, State.new(new_pid_mapping, new_chat_mapping)}
  end

  defp start_session(chat_id, state) do
    {:ok, pid} = SessionSupervisor.start_child(chat_id)
    _ref = Process.monitor(pid)
    new_pid_mapping = Map.put(state.pid_mapping, pid, chat_id)
    new_chat_mapping = Map.put(state.chat_mapping, chat_id, pid)

    {:ok, pid, State.new(new_pid_mapping, new_chat_mapping)}
  end
end
