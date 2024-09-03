defmodule Needle.UID.MixProject do
  use Mix.Project

  def project do
    [
      app: :needle_uid,
      version: "0.0.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Hybrid prefixed UUIDv7 and ULID data type for Ecto",
      homepage_url: "https://github.com/bonfire-networks/needle_uid",
      source_url: "https://github.com/bonfire-networks/needle_uid",
      package: [
        licenses: ["MIT"],
        links: %{
          "Repository" => "https://github.com/bonfire-networks/needle_uid",
          "Hexdocs" => "https://hexdocs.pm/needle_uid"
        }
      ],
      docs: [
        # The first page to display from the docs
        main: "readme",
        # extra pages to include
        extras: ["README.md"]
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  defp deps do
    [
      {:ecto, "~> 3.12"},
      {:untangle, "~> 0.3"},
      # for ULID support
      {:needle_ulid, "~> 0.3"},
      # for UUID support
      {:pride, "~> 0.0.1"}
    ]
  end
end
