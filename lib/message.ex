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

  def do_process(%{"callback_query" => msg_data} = msg) do
    Logger.debug("Processing callback query: #{inspect(msg)}")
    %{"data" => callback_data} = msg_data
    %{"message" => %{"chat" => %{"id" => chat_id}}} = msg_data
    %{"from" => %{"language_code" => lang}} = msg_data

    chat_id = to_string(chat_id)

    :ok = Session.process_message(chat_id, callback_data, lang)
  end

  def do_process(%{"message" => msg_data} = msg) do
    Logger.debug("Processing message: #{inspect(msg)}")
    %{"chat" => %{"id" => chat_id}} = msg_data
    %{"from" => %{"language_code" => lang}} = msg_data

    chat_id = to_string(chat_id)

    case msg_data do
      %{"text" => msg} ->
        :ok = Session.process_message(chat_id, msg, lang)

      _ ->
        :ok =
          Session.send_message(
            :external,
            chat_id,
            James.Text.Codes.invalid_message_type(),
            lang
          )
    end
  end

  def do_process(msg) do
    Logger.warn("Unknown event: #{inspect(msg)}")
  end
end
