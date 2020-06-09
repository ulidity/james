defmodule James.Text.EN do
  use James.Text

  defmsg(:INVALID_MESSAGE_TYPE, [
    """
    Sorry. I can only inderstand text messages
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
    Please, enter a valid command
    """
  ])

  defmsg(:ENTER_REMINDER_TITLE, [
    """
    What should i remind you about?
    """
  ])

  defmsg(:ENTER_REMINDER_TIMEOUT, [
    """
    In how much time should i do that?
    """
  ])

  defmsg(:REMINDER_CREATED, [
    """
    Great! You'll be reminded!
    """
  ])

  defmsg(:INVALID_REMINDER_TIMEOUT, [
    """
    Wrong format
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
    Reminding!
    <%= reminder %>
    """
  ])
end
