defmodule Elixir.Janus.Transport.WS.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/software-mansion-labs/elixir-janus-transport-ws"

  def project do
    [
      app: :elixir_janus_transport_ws,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "ElixirJanus transport implementation on websockets",
      package: package(),

      # docs
      name: "Elixir Janus Transport WS",
      source_url: @github_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:elixir_janus, github: "software-mansion-labs/elixir-janus"},

      # adapter clients
      {:websockex, "~> 0.4.2", optional: true},

      # DEV
      {:ex_doc, "~> 0.22", only: [:test, :dev], runtime: false},

      # TESTING
      # cowboy websocket server
      {:cowboy, "~> 2.4", only: :test},
      {:plug, "~> 1.7", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["ElixirJanus Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}"
    ]
  end
end
