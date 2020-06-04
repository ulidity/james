defmodule James.Message do
  require Logger

  alias James.Session

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

    chat_id = to_string(chat_id)

    case data do
      %{"text" => msg} ->
        :ok = Session.process_message(chat_id, msg, lang)

      _ ->
        :ok =
          Session.send_message(
            :external,
            chat_id,
            "WRONG_MESSAGE_TYPE",
            lang
          )
    end
  end

  def do_process(msg) do
    Logger.warn("Unknown event: #{inspect(msg)}")
  end
end
