defmodule Otis.Mixfile do
  use Mix.Project

  def project do
    [app: :otis,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     consolidate_protocols: Mix.env != :test,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ mod: {Otis, []},
      applications: [
        :logger,
        :monotonic,
        :sqlite_ecto,
        :ecto,
        :ranch,
        :nerves_ssdp_server,
        :gproc,
        :erlsom,
        :otis_library,
        :mdns,
        :uuid,
        :poolboy,
        # :logger_file_backend,
      ],
      included_applications: [
        :dnssd,
      ],
      extra_applications: [],
      env: [
        receiver_logger: [addr: {224,0,0,224}, port: 9999],
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [ {:dnssd, github: "benoitc/dnssd_erlang", manager: :rebar},
      {:poolboy, "~> 1.4"},
      {:monotonic, github: "magnetised/monotonic.ex"},
      {:erlsom, github: "willemdj/erlsom"},
      {:uuid, "~> 1.1"},
      {:sqlite_ecto, github: "magnetised/sqlite_ecto"},
      {:ecto, "~> 1.0"},
      {:ranch, "~> 1.0", [optional: false, hex: :ranch, manager: :rebar]},
      {:faker, "~> 0.5", only: :test},
      {:otis_library, in_umbrella: true},
      {:nerves_ssdp_server, "~> 0.2.1"},
      {:gproc, "~> 0.5.0"},
      {:mdns, "~> 0.1.5"},
      {:external_process, in_umbrella: true},
      {:gen_stage, "~> 0.1"},
    ]
  end
end
