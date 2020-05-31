defmodule James.Text do
  alias James.Text.RU
  alias James.Text.EN

  def message({code, data}, lang) do
    mod = get_mod(lang)

    {:ok, apply(mod, :message, [code, data])}
  end

  def message(code, lang) do
    mod = get_mod(lang)

    {:ok, apply(mod, :message, [code])}
  end

  def get_mod("en"), do: EN
  def get_mod("ru"), do: RU
  def get_mod(_), do: EN
end
