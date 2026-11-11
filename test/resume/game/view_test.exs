defmodule Resume.Game.ViewTest do
  use ExUnit.Case, async: true

  alias Resume.Game.Snake
  alias Resume.Game.View
  alias Resume.Game.Vm

  defp assigns(game, overrides \\ %{}) do
    Map.merge(
      %{
        game: game,
        best: 7,
        vm: Vm.snapshot(),
        server: %{pid: "#PID<0.123.0>", ticks: 42, reductions: 9_001},
        log: [~s(cast "action"), ~s(cast "mount")]
      },
      overrides
    )
  end

  defp game(status \\ :ready) do
    %{Snake.new(width: 8, height: 8, pick: fn _free -> {0, 0} end) | status: status}
  end

  describe "Resume.Game.View.regions/1" do
    test "places the snake and the food on the grid by row and column" do
      %{"board" => board} = View.regions(assigns(game(:playing)))

      assert board =~ "--columns: 8; --rows: 8"
      assert board =~ ~s(class="cell snake head" style="grid-area: 5 / 5")
      assert board =~ ~s(class="cell snake" style="grid-area: 5 / 4")
      assert board =~ ~s(class="cell food" style="grid-area: 1 / 1")
      refute board =~ "overlay"
    end

    test "explains each stopped state over the board and on the action button" do
      for {status, title, label} <- [
            {:ready, "Bullet Points", "Start"},
            {:paused, "Paused", "Resume"},
            {:over, "Game over", "Play again"}
          ] do
        regions = View.regions(assigns(game(status)))

        assert regions["board"] =~ title
        assert regions["action"] =~ label
      end
    end

    test "shows the score beside the best score" do
      %{"hud" => hud} = View.regions(assigns(%{game() | score: 3}))

      assert hud =~ ~r/Score.*3.*Best.*7/s
    end

    test "lists VM facts, the game server and its recent messages in the console" do
      %{"console" => console} = View.regions(assigns(game()))

      assert console =~ "Elixir #{System.version()} on OTP #{System.otp_release()}"
      assert console =~ "#PID&lt;0.123.0&gt;"
      assert console =~ ~r/Ticks handled.*42/s
      assert console =~ "cast &quot;action&quot;"
    end

    test "says so when no messages have arrived yet" do
      assert View.regions(assigns(game(), %{log: []}))["console"] =~ "Nothing yet."
    end
  end
end
