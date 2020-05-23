defmodule James.Error.EN do
  def message("WRONG_MESSAGE_TYPE"),
    do:
      Enum.random([
        "Sorry. I can only inderstand text messages",
        "Unfortunately i only understand text",
        "Please try entering a text message"
      ])
end
