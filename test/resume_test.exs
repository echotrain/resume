defmodule ResumeTest do
  use ExUnit.Case, async: true

  alias Resume.Fixtures

  @email ~r/[\w.+-]+@[\w-]+\.[a-z]{2,}/i
  @phone ~r/\(?\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}/

  describe "Resume.load!/1" do
    test "decodes the published content" do
      assert %Resume.Content{name: "Josh Anderson", experience: [_ | _]} = Resume.load!()
    end

    @tag :tmp_dir
    test "raises on malformed content", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "resume.json")
      File.write!(path, JSON.encode!(Map.delete(Fixtures.content_map(), "summary")))

      assert_raise ArgumentError, ~s(resume content: resume is missing "summary"), fn -> Resume.load!(path) end
    end
  end

  describe "Resume.render/1" do
    test "keeps phone numbers and email addresses out of the published page" do
      html = Resume.load!() |> Resume.render() |> IO.iodata_to_binary()

      refute html =~ @email
      refute html =~ @phone
      refute html =~ "mailto:"
      refute html =~ "tel:"
    end

    test "keeps phone numbers and email addresses out of the content file" do
      json = File.read!(Resume.content_path())

      refute json =~ @email
      refute json =~ @phone
    end
  end

  describe "Resume.build/2" do
    @tag :tmp_dir
    test "writes the page with the assets it references", %{tmp_dir: tmp_dir} do
      assert :ok = Resume.build(tmp_dir, Fixtures.content())

      html = File.read!(Path.join(tmp_dir, "index.html"))
      assert html =~ "<!DOCTYPE html>"
      assert html =~ "Ada Example"

      for [_match, asset] <- Regex.scan(~r/(?:href|src)="(assets\/[^"]+)"/, html) do
        assert File.exists?(Path.join(tmp_dir, asset)), "missing #{asset}"
      end

      assert [_normal, _italic] = Path.wildcard(Path.join(tmp_dir, "assets/fonts/*.woff2"))
    end

    @tag :tmp_dir
    test "links to the source assets on request", %{tmp_dir: tmp_dir} do
      assert :ok = Resume.build(tmp_dir, Fixtures.content(), assets: :link)

      assert File.read_link!(Path.join(tmp_dir, "assets")) == Path.expand("assets")
      assert File.exists?(Path.join(tmp_dir, "assets/css/resume.css"))
    end

    @tag :tmp_dir
    test "replaces a linked assets folder with a copy, leaving the source intact", %{tmp_dir: tmp_dir} do
      Resume.build(tmp_dir, Fixtures.content(), assets: :link)
      Resume.build(tmp_dir, Fixtures.content(), assets: :copy)

      assert {:error, :einval} = File.read_link(Path.join(tmp_dir, "assets"))
      assert File.read!(Path.join(tmp_dir, "assets/css/resume.css")) == File.read!("assets/css/resume.css")
    end
  end
end
