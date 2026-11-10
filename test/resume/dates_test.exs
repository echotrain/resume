defmodule Resume.DatesTest do
  use ExUnit.Case, async: true

  doctest Resume.Dates

  alias Resume.Dates
  alias Resume.Fixtures

  describe "Resume.Dates.format_month/1" do
    test "rejects anything that is not a YYYY-MM month" do
      assert_raise ArgumentError, ~r/expected a "YYYY-MM" month, got "2024-13"/, fn ->
        Dates.format_month("2024-13")
      end

      assert_raise ArgumentError, ~r/got "Sep 2024"/, fn -> Dates.format_month("Sep 2024") end
    end
  end

  describe "Resume.Dates.span/1" do
    test "covers the earliest start to the latest end across roles" do
      assert Dates.span(Fixtures.employer()) == {"2017-08", "2024-08"}
    end

    test "has no end while any role is current" do
      roles = [
        Fixtures.role_map(%{"start" => "2022-05", "end" => nil}),
        Fixtures.role_map(%{"start" => "2020-01", "end" => "2022-05"})
      ]

      assert Dates.span(Fixtures.employer(%{"roles" => roles})) == {"2020-01", nil}
    end
  end

  describe "Resume.Dates.tenure/3" do
    test "measures a current role up to today" do
      assert Dates.tenure("2024-09", nil, ~D[2024-11-10]) == "2 mos"
      assert Dates.tenure("2023-10", nil, ~D[2024-11-10]) == "1 yr 1 mo"
    end
  end
end
