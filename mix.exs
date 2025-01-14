defmodule Buck.MixProject do
  use Mix.Project

  @source_url "https://github.com/bytecheck/buck"
  @default_branch "main"

  def project do
    [
      app: :buck,
      version: _version(),
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: _deps(),
      docs: _docs(),
      package: _package(),
      elixirc_paths: _elixirc_paths(Mix.env()),
      description: _description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp _elixirc_paths(:test), do: ["lib", "test/support"]

  defp _elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp _deps do
    [
      {:amqp, "~> 4.0"},
      {:rabbit, "~> 0.20"},
      # test/docs
      {:ex_doc, "~> 0.36", only: [:test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp _version do
    case Regex.run(~r/^v([\d\.a-z_A-Z\-]+)/, File.read!(Path.join(__DIR__, ".app_version")),
           capture: :all_but_first
         ) do
      [version] -> version
      nil -> "0.0.0-default"
    end
  end

  defp _docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md": [title: "Changelog"]]
    ]
  end

  defp _description do
    "An opinionated rabbitmq client wrapper for `rabbit` library."
  end

  defp _package do
    [
      maintainers: ["bytecheck"],
      name: "buck",
      files: ~w(lib .formatter.exs mix.exs README.md .app_version LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "ChangeLog" => "#{@source_url}/blob/#{@default_branch}/CHANGELOG.md",
        "GitHub" => "#{@source_url}"
      }
    ]
  end
end
