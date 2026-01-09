defmodule Needle.UID.MixProject do
  use Mix.Project

  def project do
    [
      app: :needle_uid,
      version: "0.0.2",
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
      {:ecto, "~> 3.13"},
      {:untangle, "~> 0.4"},
      # for ULID support
      {:needle_ulid, 
      "~> 0.5", 
      #  git: "https://github.com/bonfire-networks/needle_ulid"
      },
      # for UUID support
      {
        :pride,
        "~> 0.0.2",
        optional: true,
        # git: "https://github.com/bonfire-networks/pride"
      },
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
