defmodule Mix.Tasks.Resume.Build do
  @shortdoc "Builds the static resume site"

  @moduledoc """
  Builds the static resume site into `output/` (or the directory given).

      mix resume.build
      mix resume.build path/to/dir
      mix resume.build --copy

  In the `dev` environment the output links to `assets/` instead of copying
  it, so CSS and JS edits show up on refresh. Any other environment, or the
  `--copy` flag, copies the assets so the output is self-contained.
  """

  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, paths} = OptionParser.parse!(args, strict: [copy: :boolean])
    output_dir = List.first(paths, "output")
    assets = assets_mode(Keyword.get(opts, :copy, false), Mix.env())

    {microseconds, :ok} = :timer.tc(fn -> Resume.build(output_dir, Resume.load!(), assets: assets) end)

    Mix.shell().info("Built #{Path.join(output_dir, "index.html")} in #{div(microseconds, 1000)}ms (assets: #{assets})")
  end

  defp assets_mode(false, :dev), do: :link
  defp assets_mode(_copy?, _env), do: :copy
end
