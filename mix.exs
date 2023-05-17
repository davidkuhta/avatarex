defmodule Avatarex.MixProject do
  use Mix.Project

  def project do
    [
      app: :avatarex,
      version: "0.1.1",
      elixir: "~> 1.14",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Avatarex",
      source_url: "https://github.com/davidkuhta/avatarex",
      # homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      docs: [
        main: "Avatarex", # The main page in the docs
        # logo: "path/to/logo.png",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:image, "~> 0.31.1"},
    ]
  end

    defp description() do
    "`Avatarex` is an elixir package for generating unique, reproducible Avatars"
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/davidkuhta/avatarex"}
    ]
  end
end