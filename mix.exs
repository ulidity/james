defmodule James.MixProject do
  use Mix.Project

  def project do
    [
      app: :james,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:confex, :logger],
      mod: {James.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:confex, "~> 3.0"},
      {:typed_struct, "~> 0.1"},
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1"},
      {:gen_state_machine, "~> 2.0"},
      {:redix, "~> 0.10"},
      {:ulid, "~> 0.2"},
      {:rexbug, "~> 1.0"}
    ]
  end
end
