defmodule James.Text.RU do
  use James.Text

  defmsg(:INVALID_MESSAGE_TYPE, [
    """
    Поалуйста, введите тестковое сообщение
    """,
    """
    К сожалению, я понимаю только текст
    """
  ])

  defmsg(:INVALID_COMMAND, [
    """
    Пожалуйста, введите команду
    """
  ])

  defmsg(:ENTER_REMINDER_TITLE, [
    """
    О чем вам напомнить?
    """
  ])

  defmsg(:ENTER_REMINDER_TIMEOUT, [
    """
    Через какое время вам об этом напомнить?
    """
  ])

  defmsg(:REMINDER_CREATED, [
    """
    Отлично! Обязательно напомню!
    """
  ])

  defmsg(:INVALID_REMINDER_TIMEOUT, [
    """
    Неверный формат
    """
  ])

  defmsg(:COMMAND_CANCELED, [
    """
    Отмена
    """
  ])

  defmsg(:COMMAND_NOT_APPLICABLE, [
    """
    Команда не может быть применена
    """
  ])

  defmsg(:REMINDER, [
    """
    Напоминаю!
    <%= reminder %>
    """
  ])

  defmsg(:WELCOME, [
    """
    Добро пожаловать!
    """
  ])
end
