defmodule James.Error do
  alias James.Error.RU
  alias James.Error.EN

  def message(code, lang) do
    mod = get_mod(lang)

    apply(mod, :message, [code])
  end

  def get_mod("en"), do: EN
  def get_mod("ru"), do: RU
  def get_mod(_), do: EN
end
