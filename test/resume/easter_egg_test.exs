defmodule Resume.EasterEggTest do
  use ExUnit.Case, async: true

  alias Resume.EasterEgg

  describe "Resume.EasterEgg.greeting/0" do
    test "reports the running VM and the calling process" do
      greeting = EasterEgg.greeting()

      assert greeting =~ "Elixir #{System.version()} on OTP #{System.otp_release()}"
      assert greeting =~ inspect(self())
    end
  end

  describe "Resume.EasterEgg.greet/0" do
    test "succeeds outside the browser, where Popcorn's JavaScript bridge is a no-op" do
      assert EasterEgg.greet() == :ok
    end
  end
end
