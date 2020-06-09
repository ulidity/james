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
    __*Ошибка*__: Неверная команда

    *Подсказка*:
    ```
    Введите одну из предложенных команд.
    ```
    /new \\- создать новое напоминание
    /cancel \\- отменить текущую команду
    """
  ])

  defmsg(:ENTER_REMINDER_TITLE, [
    """
    О чем вам напомнить
    """
  ])

  defmsg(:ENTER_REMINDER_TIMEOUT, [
    """
    Через какое время вам об этом напомнить
    """
  ])

  defmsg(:REMINDER_CREATED, [
    """
    Отлично Обязательно напомню
    """
  ])

  defmsg(:REMINDER_COMPLETED, [
    """
    Reminder completed
    """
  ])

  defmsg(:REMINDER_ALREADY_COMPLETED, [
    """
    Reminder already completed
    """
  ])

  defmsg(:INVALID_REMINDER_TIMEOUT, [
    """
    __*Ошибка*__: Неверный формат

    *Подсказка*:
    ```
    Чтобы я понял, когда вам нужно напомнить о чем-то, период времени должен быть описан в определенном формате.
    ```
    *Примеры*:
    \\- десять секунд ```10s```
    \\- десять минут ```10m```
    \\- один час ```1h```
    \\- полтора часа ```1h30m```
    \\- один день ```1d```
    \\- одна неделя ```7d```

    __*d*__ \\- дни
    __*h*__ \\- часы
    __*m*__ \\- минуты
    __*s*__ \\- секунды
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
    *Напоминаю\\!*

    ```
    <%= reminder %>
    ```
    """,
    """
    *Время пришло\\!*

    ```
    <%= reminder %>
    ```
    """
  ])

  defmsg(:WELCOME, [
    """
    Добро пожаловать
    """
  ])

  defmsg(:BUTTON_CONFIRM_REMINDER_COMPLETION, ["Готово!"])
end
