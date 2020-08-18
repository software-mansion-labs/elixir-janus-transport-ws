defmodule ElixirJanusTransportWs.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_janus_transport_ws,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

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
      {:mock, "~> 0.3.0", only: :test},
      {:websockex, "~> 0.4.2"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
    ]
  end
end
