defmodule Resume.ContentTest do
  use ExUnit.Case, async: true

  alias Resume.Content
  alias Resume.Content.Employer
  alias Resume.Content.Highlight
  alias Resume.Content.Role
  alias Resume.Fixtures

  describe "Resume.Content.from_map/1" do
    test "nests roles and highlights under their employer" do
      assert %Content{experience: [%Employer{company: "Acme Rockets", roles: [senior, junior]}]} =
               Content.from_map(Fixtures.content_map())

      assert %Role{title: "Senior Engineer", start: "2021-03", end: "2024-08"} = senior
      assert %Role{title: "Engineer"} = junior

      assert senior.highlights == [
               %Highlight{lead: "Launch control:", text: "Shipped the countdown."},
               %Highlight{lead: nil, text: "Kept the lights on."}
             ]
    end

    test "treats a role without an end month as current" do
      employer = Fixtures.employer_map(%{"roles" => [Fixtures.role_map(%{"end" => nil})]})

      assert %Content{experience: [%Employer{roles: [%Role{end: nil}]}]} =
               Content.from_map(Fixtures.content_map(%{"experience" => [employer]}))
    end

    test "names the missing key" do
      employer = Fixtures.employer_map(%{"roles" => [Map.delete(Fixtures.role_map(), "start")]})

      assert_raise ArgumentError, ~s(resume content: role is missing "start"), fn ->
        Content.from_map(Fixtures.content_map(%{"experience" => [employer]}))
      end
    end
  end
end
