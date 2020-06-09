defmodule James.Text do
  alias James.Text.RU
  alias James.Text.EN

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :message, accumulate: true)
      import unquote(__MODULE__), only: [defmsg: 2]
      @before_compile unquote(__MODULE__)

      def message(code, data \\ [])
    end
  end

  defmacro __before_compile__(env) do
    defined_messages = Module.get_attribute(env.module, :message)
    required_messages = James.Text.codes()

    diff = required_messages -- defined_messages

    if not Enum.empty?(diff) do
      raise("Required messages #{inspect(diff)} not defined")
    end

    diff = defined_messages -- required_messages

    if not Enum.empty?(diff) do
      raise("Unexpected messages #{inspect(diff)} defined")
    end
  end

  defmacro defmsg(message, variants) do
    quote do
      @message unquote(message)
      def message(unquote(message), data) do
        msg = Enum.random(unquote(variants))
        EEx.eval_string(msg, data)
      end
    end
  end

  defmacro defcodes() do
    for code <- __MODULE__.codes() do
      function =
        code
        |> Atom.to_string()
        |> String.downcase()
        |> String.to_atom()

      code =
        code
        |> Atom.to_string()
        |> String.upcase()
        |> String.to_atom()

      quote do
        def unquote(function)(), do: unquote(code)
      end
    end
  end

  def codes,
    do: [
      :WELCOME,
      :INVALID_MESSAGE_TYPE,
      :INVALID_COMMAND,
      :COMMAND_CANCELED,
      :ENTER_REMINDER_TITLE,
      :ENTER_REMINDER_TIMEOUT,
      :INVALID_REMINDER_TIMEOUT,
      :COMMAND_NOT_APPLICABLE,
      :REMINDER_CREATED,
      :REMINDER_ALREADY_COMPLETED,
      :REMINDER_COMPLETED,
      :REMINDER,
      :BUTTON_CONFIRM_REMINDER_COMPLETION
    ]

  def message({code, data}, lang) do
    mod = get_mod(lang)

    apply(mod, :message, [code, data])
  end

  def message(code, lang) do
    mod = get_mod(lang)

    apply(mod, :message, [code])
  end

  def get_mod("en"), do: EN
  def get_mod("ru"), do: RU
  def get_mod(_), do: EN
end

defmodule James.Text.Codes do
  require James.Text

  James.Text.defcodes()
end
