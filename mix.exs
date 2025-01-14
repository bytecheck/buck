defmodule Buck.MixProject do
  use Mix.Project

  def project do
    [
      app: :buck,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 4.0", override: true},
      {:rabbit, "~> 0.20"}
    ]
  end
end
