defmodule James.Message do
  require Logger

  alias James.Session
  alias James.Error

  def process(msg) do
    Task.Supervisor.start_child(
      James.Message.Processor,
      fn ->
        do_process(msg)
      end,
      restart: :temporary
    )
  end

  def do_process(%{"message" => data} = msg) do
    Logger.debug("Processing message: #{inspect(msg)}")
    %{"chat" => %{"id" => chat_id}} = data
    %{"from" => %{"language_code" => lang}} = data

    case data do
      %{"text" => msg} ->
        Session.respond(chat_id, msg)

      _ ->
        error_msg = Error.message("WRONG_MESSAGE_TYPE", lang)
        Session.respond(chat_id, error_msg)
    end
  end

  def do_process(msg) do
    Logger.warn("Unknown event: #{inspect(msg)}")
  end
end
