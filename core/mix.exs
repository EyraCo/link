defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      source_url: "https://github.com/eyra/eylixir",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # The main page in the docs
      docs: [
        main: "readme",
        logo: "assets/static/images/eyra-logo.svg",
        extras: [
          "../README.md",
          "../guides/development_setup.md",
          "../guides/authorization.md"
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [
          # :unmatched_returns,
          :error_handling,
          :race_conditions,
          :no_opaque
        ],
        paths: dialyzer_framework_paths()
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Core.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["bundles", "lib", "test", "test/support"]
  defp elixirc_paths(_), do: ["bundles", "lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:green_light, path: "../frameworks/green_light"},
      {:eyra_ui, path: "../frameworks/eyra_ui"},
      {:assent, "~> 0.1.23"},
      {:bcrypt_elixir, "~> 2.0"},
      {:phoenix, "~> 1.5.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_live_view, "~> 0.15.1"},
      {:floki, ">= 0.27.0", only: :test},
      {:ecto_sql, "~> 3.4"},
      {:ecto_commons, "~> 0.3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:faker, "~> 0.16"},
      {:surface, "~> 0.4.0"},
      {:timex, "~> 3.6"},
      {:bamboo, "~> 2.0.1"},
      {:bamboo_phoenix, "~> 1.0.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:currency_formatter, "~> 0.4"},
      {:web_push_encryption, "~> 0.3"},
      {:pigeon, "~> 1.6.1"},
      {:kadabra, "~> 0.6.0"},
      {:oban, "~> 2.7"},
      # i18n
      {:ex_cldr, "~> 2.18"},
      {:ex_cldr_numbers, "~> 2.16"},
      {:ex_cldr_dates_times, "~> 2.6"},
      {:site_encrypt, "~> 0.4"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:certifi, "~> 2.4"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:ssl_verify_fun, "~> 1.1"},
      # Dev and test deps
      {:surface_catalogue, "~> 0.0.7", only: [:dev, :test]},
      {:file_system, "~> 0.2", only: [:dev, :test]},
      {:exsync, "~> 0.2", only: :dev},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:progress_bar, "~> 2.0.1", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev, :test], runtime: false},
      {:table_rex, "~> 3.0.0"},
      {:phx_gen_auth, "~> 0.6", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      i18n: [
        "gettext.extract --merge priv/gettext"
      ],
      makedocs: ["deps.get", "docs -o doc/output"]
    ]
  end

  defp dialyzer_framework_paths do
    env = Mix.env()
    ["green_light", "eyra_ui"] |> Enum.map(&"_build/#{env}/lib/#{&1}/ebin")
  end
end
