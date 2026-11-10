defmodule Resume do
  @moduledoc """
  Builds the static resume site: `priv/resume.json` in, `output/index.html` out.

  Run `mix resume.build` to generate the site.
  """

  alias Resume.Components
  alias Resume.Content

  @assets_dir "assets"
  @default_output_dir "output"

  @doc "Path to the resume content shipped with the app."
  @spec content_path() :: Path.t()
  def content_path, do: Application.app_dir(:resume, "priv/resume.json")

  @doc "Reads and decodes a resume content file, raising if it is missing or malformed."
  @spec load!(Path.t()) :: Content.t()
  def load!(path \\ content_path()) do
    path |> File.read!() |> JSON.decode!() |> Content.from_map()
  end

  @doc "Renders the resume to a complete HTML document."
  @spec render(Content.t()) :: iodata()
  def render(%Content{} = content) do
    %{resume: content} |> Components.page() |> Phoenix.HTML.Safe.to_iodata()
  end

  @doc """
  Writes the site to `output_dir`: `index.html` plus the assets it references.

  ## Options

    * `:assets` - `:copy` (default) copies `assets/` so the output is
      self-contained for deployment. `:link` symlinks it instead, so local
      edits to CSS and JS show up on refresh without rebuilding.
  """
  @spec build(Path.t(), Content.t(), assets: :copy | :link) :: :ok
  def build(output_dir \\ @default_output_dir, %Content{} = content \\ load!(), opts \\ []) do
    File.mkdir_p!(output_dir)
    File.write!(Path.join(output_dir, "index.html"), render(content))
    place_assets(Keyword.get(opts, :assets, :copy), Path.join(output_dir, "assets"))
  end

  # The old target is removed first: copying into a leftover symlink would
  # write the assets onto themselves. `rm_rf!` removes a link, not its target.
  defp place_assets(mode, target) do
    File.rm_rf!(target)
    write_assets(mode, target)
    :ok
  end

  defp write_assets(:copy, target), do: File.cp_r!(@assets_dir, target)
  defp write_assets(:link, target), do: File.ln_s!(Path.expand(@assets_dir), target)
end
