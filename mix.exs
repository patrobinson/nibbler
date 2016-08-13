defmodule Nibbler.Mixfile do
  use Mix.Project

  def project do
    [app: :nibbler,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      mod: {Nibbler, []},
      applications: [:logger, :epcap]
    ]
  end

  defp deps do
    [{:epcap, github: "msantos/epcap"}]
  end
end
