defmodule Avatarex.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :avatarex,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Avatarex",
      source_url: "https://github.com/davidkuhta/avatarex",
      # homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # For fast, multi-threaded, pipelined image processing
      {:image, "~> 0.31.1"},

      # For release management
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    ]
  end

  defp description() do
    "`Avatarex` is an elixir package for generating unique, reproducible avatars"
  end

  defp docs() do
    [
      main: "Avatarex",
      logo: "logo.png",
      extras: ["README.md", "LICENSE"]
    ]
  end

  defp package() do
    [
      maintainers: ["David Kuhta"],
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: links()
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/davidkuhta/avatarex",
      "Readme" => "https://github.com/davidkuhta/avatarex/blob/v#{@version}/README.md",
      "Vix" => "https://github.com/akash-akya/vix",
      "libvips" => "https://www.libvips.org"
    }
  end

  defp elixirc_paths(:test), do: ["lib","test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
