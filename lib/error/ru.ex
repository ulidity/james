defmodule James.Error.RU do
  def message("WRONG_MESSAGE_TYPE"),
    do:
      Enum.random([
        "Поалуйста, введите тестковое сообщение",
        "К сожалению, я понимаю только текст"
      ])
end
