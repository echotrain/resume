defmodule Resume.Game.ServerTest do
  use ExUnit.Case, async: true

  alias Resume.Game.Server
  alias Resume.Game.Snake

  # Food sits directly ahead of the starting snake, so the first tick eats it.
  setup %{test: test} do
    food_ahead = fn free -> Enum.find(free, hd(free), &(&1 == {5, 4})) end
    server = start_supervised!({Server, name: test, width: 8, height: 8, pick: food_ahead})

    %{server: server}
  end

  defp state(server), do: :sys.get_state(server)

  describe "Resume.Game.Server.handle_cast/2" do
    test "renders every region when the page mounts", %{server: server} do
      GenServer.cast(server, "mount")

      assert %Server{mounted?: true, rendered: rendered} = state(server)
      assert rendered |> Map.keys() |> Enum.sort() == ~w(action board console hud)
      assert rendered["action"] =~ "Start"
    end

    test "starts, pauses and resumes the game from the action button", %{server: server} do
      GenServer.cast(server, "action")
      assert %Server{game: %Snake{status: :playing}, tick_timer: timer} = state(server)
      assert is_reference(timer)

      GenServer.cast(server, "action")
      assert %Server{game: %Snake{status: :paused}, tick_timer: nil} = state(server)

      GenServer.cast(server, "action")
      assert %Server{game: %Snake{status: :playing}} = state(server)
    end

    test "queues a turn sent by the page and logs it", %{server: server} do
      GenServer.cast(server, "action")
      GenServer.cast(server, ["turn", "up"])

      assert %Server{game: %Snake{turns: [:up]}, log: [~s(cast ["turn", "up"]) | _older]} = state(server)
    end

    test "ignores input it does not understand", %{server: server} do
      GenServer.cast(server, "action")
      GenServer.cast(server, ["turn", "sideways"])
      GenServer.cast(server, %{"anything" => "else"})

      assert %Server{game: %Snake{turns: []}, log: [~s(cast "action")]} = state(server)
    end
  end

  describe "Resume.Game.Server.handle_info/2" do
    test "advances the game on a tick and keeps the best score", %{server: server} do
      GenServer.cast(server, "action")
      send(server, :tick)

      assert %Server{game: %Snake{score: score}, best: best, ticks: ticks, log: log} = state(server)
      assert score >= 1
      assert best == score
      assert ticks >= 1
      assert Enum.any?(log, &(&1 =~ "ate a bullet point"))
    end

    test "leaves a game that has not started untouched", %{server: server} do
      before = state(server).game
      send(server, :tick)

      assert state(server).game == before
    end
  end
end
