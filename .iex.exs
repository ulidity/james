defmodule Dev do
  @command_confirm_reminder_completion "confirm_reminder_completion"

  def send_message(msg, chat_id, opts \\ [lang: "en"]) do
    James.Message.process(%{"message" => %{
      "chat" => %{"id" => chat_id},
      "from" => %{"language_code" => opts[:lang]},
      "text" => msg
    }})
  end

  def send_callback_query(command, data, chat_id, opts \\ [lang: "en"]) do
    James.Message.process(%{"callback_query" => %{
      "data" => "/#{command}#{data[:reminder_id]}",
      "from" => %{"language_code" => opts[:lang]},
      "message" => %{"chat" => %{"id" => chat_id}}
    }})
  end

  def confirm_reminder_completion(reminder_id, chat_id, opts \\ [lang: "en"]) do
    send_callback_query(
      @command_confirm_reminder_completion, [reminder_id: reminder_id], chat_id, opts
    )
  end
end
