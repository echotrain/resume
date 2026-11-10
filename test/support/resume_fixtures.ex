defmodule Resume.Fixtures do
  @moduledoc "Decoded-JSON shaped resume content for tests."

  alias Resume.Content

  @spec content_map(map()) :: map()
  def content_map(overrides \\ %{}) do
    Map.merge(
      %{
        "name" => "Ada Example",
        "title" => "Staff Engineer",
        "summary" => "Builds dependable systems.",
        "links" => [%{"label" => "example.com/ada", "url" => "https://example.com/ada"}],
        "experience" => [employer_map()],
        "technologies" => [%{"label" => "Languages", "items" => ["Elixir", "Erlang"]}],
        "education" => [
          %{"degree" => "BS, Computer Science", "school" => "Example University", "date" => "Spring 2015"}
        ],
        "patents" => [%{"title" => "A Widget", "number" => "US-1-B1", "issued" => "Jan 1, 2020"}]
      },
      overrides
    )
  end

  @spec employer_map(map()) :: map()
  def employer_map(overrides \\ %{}) do
    Map.merge(
      %{
        "company" => "Acme Rockets",
        "blurb" => "Rockets for coyotes.",
        "roles" => [
          role_map(%{"title" => "Senior Engineer", "start" => "2021-03", "end" => "2024-08"}),
          role_map(%{"title" => "Engineer", "start" => "2017-08", "end" => "2021-03"})
        ]
      },
      overrides
    )
  end

  @spec role_map(map()) :: map()
  def role_map(overrides \\ %{}) do
    Map.merge(
      %{
        "title" => "Engineer",
        "start" => "2020-01",
        "end" => "2021-01",
        "highlights" => [%{"lead" => "Launch control:", "text" => "Shipped the countdown."}, "Kept the lights on."]
      },
      overrides
    )
  end

  @spec content(map()) :: Content.t()
  def content(overrides \\ %{}), do: overrides |> content_map() |> Content.from_map()

  @spec employer(map()) :: Content.Employer.t()
  def employer(overrides \\ %{}), do: overrides |> employer_map() |> Content.Employer.from_map()
end
