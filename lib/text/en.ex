defmodule James.Text.EN do
  use James.Text

  defmsg(:INVALID_MESSAGE_TYPE, [
    """
    Sorry I can only inderstand text messages
    """,
    """
    Unfortunately i only understand text
    """,
    """
    Please try entering a text message
    """
  ])

  defmsg(:INVALID_COMMAND, [
    """
    __*Error*__: Invalid command

    *Hint*:
    ```
    Enter one of the following commands
    ```
    /new \\- create new reminder
    /cancel \\- cancel current command
    """
  ])

  defmsg(:ENTER_REMINDER_TITLE, [
    """
    What should i remind you about
    """
  ])

  defmsg(:ENTER_REMINDER_TIMEOUT, [
    """
    In how much time should i do that
    """
  ])

  defmsg(:REMINDER_CREATED, [
    """
    Great You'll be reminded
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
    __*Error*__: Invalid format

    *Hint*:
    ```
    The time period should be provided in a special format so that i can understand it.
    ```
    *Examples*:
    \\- ten seconds ```10s```
    \\- ten minutes ```10m```
    \\- one hour ```1h```
    \\- one hour and a half ```1h30m```
    \\- one day ```1d```
    \\- one week ```7d```

    __*d*__ \\- days
    __*h*__ \\- hours
    __*m*__ \\- minutes
    __*s*__ \\- seconds
    """
  ])

  defmsg(:WELCOME, [
    """
    Welcome
    """
  ])

  defmsg(:COMMAND_CANCELED, [
    """
    Canceled
    """
  ])

  defmsg(:COMMAND_NOT_APPLICABLE, [
    """
    Comman is not applicable
    """
  ])

  defmsg(:REMINDER, [
    """
    *Reminding\\!*

    ```
    <%= reminder %>
    ```
    """,
    """
    *It's time\\!*

    ```
    <%= reminder %>
    ```
    """
  ])

  defmsg(:BUTTON_CONFIRM_REMINDER_COMPLETION, ["Done!"])
end
