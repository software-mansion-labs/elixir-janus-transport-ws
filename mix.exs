defmodule ElixirJanusTransportWs.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_janus_transport_ws,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bunch, "~> 1.3"},
      {:jason, "~> 1.2"},
      {:elixir_janus, github: "software-mansion-labs/elixir-janus"},

      # DEV
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},

      # TESTING
      {:mock, "~> 0.3.0", only: :test},

      # cowboy websocket server
      {:cowboy, "~> 2.4", only: :test},
      {:plug, "~> 1.7", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test},

      # adapter clients
      {:websockex, "~> 0.4.2", only: :test}
    ]
  end
end
