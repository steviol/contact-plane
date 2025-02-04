defmodule ContactPlane.MixProject do
  use Mix.Project

  def project do
    [
      app: :contact_plane,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ContactPlane.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ecto, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.12"},
      {:html_entities, "~> 0.5"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
