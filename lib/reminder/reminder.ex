defmodule James.Reminder do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field(:title, String.t())
    field(:timeout, pos_integer())
  end

  def empty(), do: %Reminder{}

  def with_title(reminder, title) do
    %Reminder{reminder | title: title}
  end

  def with_timeout(reminder, timeout) do
    %Reminder{reminder | timeout: timeout}
  end
end
