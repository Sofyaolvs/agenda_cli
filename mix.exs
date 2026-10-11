defmodule AgendaCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :agenda_cli,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"}
    ]
  end

  # `mix agenda` é um atalho para `mix run -e "AgendaCli.main([])"`
  defp aliases do
    [
      agenda: ["run -e AgendaCli.main([])"]
    ]
  end
end
