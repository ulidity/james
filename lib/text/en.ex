defmodule James.Text.EN do
  def message("WRONG_MESSAGE_TYPE") do
    Enum.random([
      "Sorry. I can only inderstand text messages",
      "Unfortunately i only understand text",
      "Please try entering a text message"
    ])
  end

  def message("NOT_A_COMMAND") do
    "Please, enter a valid command"
  end

  def message("ENTER_REMINDER_TITLE") do
    "What should i remind you about?"
  end

  def message("ENTER_REMINDER_TIMEOUT") do
    "In how much time should i do that?"
  end

  def message("REMINDER_CREATED") do
    "Great! You'll be reminded!"
  end

  def message("INVALID_REMINDER_TIMEOUT") do
    "Wrong format"
  end

  def message("REMINDER", data) do
    "Reminding!\n#{data[:title]}"
  end
end
