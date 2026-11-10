defmodule Resume.ComponentsTest do
  use ExUnit.Case, async: true

  alias Resume.Components
  alias Resume.Fixtures

  # Components that call `assign/3` need the change-tracking key HEEx normally supplies.
  defp render(component, assigns) do
    assigns |> Map.put(:__changed__, %{}) |> component.() |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp count(html, pattern), do: html |> String.split(pattern) |> length() |> Kernel.-(1)

  describe "Resume.Components.employer/1" do
    test "groups every role under one employer heading with the combined tenure" do
      html = render(&Components.employer/1, %{employer: Fixtures.employer()})

      assert count(html, "Acme Rockets") == 1
      assert count(html, ~s(<section class="role">)) == 2
      assert html =~ ~s(<span class="tenure">7 yrs</span>)
    end

    test "shows the tenure and a single date range when there is one role" do
      employer = Fixtures.employer(%{"roles" => [Fixtures.role_map()]})
      html = render(&Components.employer/1, %{employer: employer})

      assert html =~ ~s(<span class="tenure">1 yr</span>)
      assert count(html, "Jan 2020") == 1
    end
  end

  describe "Resume.Components.role/1" do
    test "bolds only the lead-in of a highlight" do
      [role | _rest] = Fixtures.employer().roles
      html = render(&Components.role/1, %{role: role, show_dates?: true})

      assert html =~ "<strong>Launch control:</strong>"
      assert count(html, "<strong") == 1
      assert html =~ "Kept the lights on."
    end
  end

  describe "Resume.Components.masthead/1" do
    test "links the profiles and leaves the contact slots empty" do
      html = render(&Components.masthead/1, %{resume: Fixtures.content()})

      assert html =~ ~s(<a href="https://example.com/ada">example.com/ada</a>)
      assert html =~ ~s(<li id="contact-phone" class="print-only" hidden></li>)
      assert html =~ ~s(<li id="contact-email" class="print-only" hidden></li>)
    end
  end
end
