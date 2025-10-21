defmodule Censor.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/zven21/censor"

  def project do
    [
      app: :censor,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Censor",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Censor.Application, []}
    ]
  end

  defp deps do
    [
      # Core
      {:cachex, "~> 3.6"},
      {:file_system, "~> 1.0", optional: true},

      # Optional integrations
      {:plug, "~> 1.14", optional: true},
      {:absinthe, "~> 1.7", optional: true},
      {:ecto, "~> 3.10", optional: true},

      # Dev & Test
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    High-performance sensitive word filtering for Elixir applications.
    Features DFA algorithm, hot reload, multiple detection modes, and framework integrations.
    """
  end

  defp package do
    [
      name: "censor",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
