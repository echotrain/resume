defmodule Resume.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      aliases: aliases(),
      app: :resume,
      deps: deps(),
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      usage_rules: usage_rules(),
      version: @version
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Resume.Application, []}
    ]
  end

  defp aliases do
    [
      check: ["format --check-formatted", "credo --strict --min-priority=higher", "test"],
      f: "format",
      # The full deployable site: the resume page plus the browser build of the
      # easter egg. Run with MIX_ENV=prod so dev-only deps are not packaged.
      "site.build": ["resume.build --copy", "popcorn.cook --out-dir output/game/out"],
      "test.html": "coveralls.html",
      "test.json": "coveralls.json"
    ]
  end

  # Mix calls `cli/0` (it must be public) to pick the env for these tasks and aliases.
  def cli do
    [
      preferred_envs: [
        check: :test,
        credo: :test,
        dialyzer: :test,
        test: :test,
        "test.html": :test,
        "test.json": :test
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # HEEx templates and function components only. `runtime: false` keeps the
      # Phoenix applications from being started, natively or in the browser.
      {:phoenix_live_view, "~> 1.2", runtime: false},

      # Spike: runs Elixir in the browser on a BEAM compiled to WebAssembly.
      {:popcorn, "~> 1.0"},

      # Dev/Test Only Deps
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18.5", only: [:test]},
      {:mimic, "~> 2.4.1", only: [:test]},
      {:usage_rules, "~> 1.2.8", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp usage_rules do
    [
      skills: [
        location: ".claude/skills",
        build: [
          "elixir-core": [
            description:
              "Use this skill when writing Elixir code. Always consult this for core Elixir idioms, pattern matching, error handling, and OTP patterns like GenServers and supervision.",
            usage_rules: [:usage_rules]
          ],
          "mimic-framework": [
            description:
              "Use this skill when working with Mimic. Always consult this when working with Mimic features, and anything related to our mocking and testing.",
            usage_rules: [:mimic, ~r/^mimic/]
          ]
        ]
      ]
    ]
  end
end
