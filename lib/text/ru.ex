defmodule James.Text.RU do
  def message("WRONG_MESSAGE_TYPE") do
    Enum.random([
      "Поалуйста, введите тестковое сообщение",
      "К сожалению, я понимаю только текст"
    ])
  end

  def message("NOT_A_COMMAND") do
    "Пожалуйста, введите команду"
  end

  def message("ENTER_REMINDER_TITLE") do
    "О чем вам напомнить?"
  end

  def message("ENTER_REMINDER_TIMEOUT") do
    "Через какое время вам об этом напомнить?"
  end

  def message("REMINDER_CREATED") do
    "Отлично! Обязательно напомню!"
  end

  def message("INVALID_REMINDER_TIMEOUT") do
    "Неверный формат"
  end

  def message("REMINDER", data) do
    "Напоминаю!\n#{data[:title]}"
  end
end
