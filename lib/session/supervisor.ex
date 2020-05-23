defmodule James.Session.Supervisor do
  use DynamicSupervisor

  alias James.Session

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(chat_id) do
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, {Session, chat_id})
  end
end
