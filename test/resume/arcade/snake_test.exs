defmodule Resume.Game.SnakeTest do
  use ExUnit.Case, async: true

  alias Resume.Game.Snake

  # An 8x8 board: the snake starts at {4, 4}, {3, 4}, {2, 4}, heading right.
  defp game(food \\ {0, 0}) do
    Snake.new(width: 8, height: 8, pick: fn _free -> food end)
  end

  defp playing(food \\ {0, 0}), do: food |> game() |> Snake.start()

  defp steer(game, directions) do
    Enum.reduce(directions, game, fn direction, game -> game |> Snake.turn(direction) |> Snake.tick() end)
  end

  describe "Resume.Game.Snake.new/1" do
    test "waits to be started with a short snake in the middle and food on a free cell" do
      game = Snake.new(width: 8, height: 8)

      assert %Snake{status: :ready, score: 0, direction: :right} = game
      assert game.snake == [{4, 4}, {3, 4}, {2, 4}]
      refute game.food in game.snake
    end
  end

  describe "Resume.Game.Snake.tick/2" do
    test "moves the snake one cell in its direction" do
      assert Snake.tick(playing()).snake == [{5, 4}, {4, 4}, {3, 4}]
    end

    test "does nothing until the game is started" do
      assert Snake.tick(game()) == game()
    end

    test "grows, scores and places new food when the snake eats" do
      game = Snake.tick(playing({5, 4}), fn _free -> {7, 7} end)

      assert game.snake == [{5, 4}, {4, 4}, {3, 4}, {2, 4}]
      assert game.score == 1
      assert game.food == {7, 7}
    end

    test "only offers free cells for the next food" do
      Snake.tick(playing({5, 4}), fn free ->
        assert length(free) == 8 * 8 - 4
        refute {5, 4} in free
        hd(free)
      end)
    end

    test "ends the game at a wall" do
      game = Enum.reduce(1..3, playing(), fn _step, game -> Snake.tick(game) end)
      assert game.status == :playing

      assert Snake.tick(game).status == :over
    end

    test "ends the game when the snake runs into itself" do
      long = %{playing() | snake: [{4, 4}, {3, 4}, {2, 4}, {1, 4}, {0, 4}]}

      assert steer(long, [:down, :left, :up]).status == :over
    end

    test "lets the head follow the tail into the cell it is leaving" do
      square = %{playing() | snake: [{4, 4}, {3, 4}, {3, 5}, {4, 5}], direction: :right}

      assert steer(square, [:down]).status == :playing
    end
  end

  describe "Resume.Game.Snake.turn/2" do
    test "ignores a turn that would reverse the snake onto itself" do
      assert Snake.turn(playing(), :left) == playing()
    end

    test "remembers two quick turns so a corner taken within one tick is not lost" do
      game = playing() |> Snake.turn(:up) |> Snake.turn(:left) |> Snake.tick() |> Snake.tick()

      assert game.snake == [{3, 3}, {4, 3}, {4, 4}]
    end

    test "is ignored unless the game is running" do
      assert Snake.turn(game(), :up) == game()
    end
  end

  describe "Resume.Game.Snake.start/2" do
    test "deals a fresh game of the same size after game over" do
      over = %{playing() | status: :over, score: 9, snake: [{0, 0}]}

      assert %Snake{status: :playing, score: 0, width: 8, height: 8, snake: [{4, 4} | _body]} = Snake.start(over)
    end
  end

  describe "Resume.Game.Snake.toggle_pause/1" do
    test "stops and resumes a running game" do
      paused = Snake.toggle_pause(playing())

      assert paused.status == :paused
      assert Snake.tick(paused) == paused
      assert Snake.toggle_pause(paused).status == :playing
    end
  end

  describe "Resume.Game.Snake.interval/1" do
    test "shortens as the score climbs, down to a floor" do
      assert Snake.interval(%{game() | score: 0}) > Snake.interval(%{game() | score: 5})
      assert Snake.interval(%{game() | score: 50}) == Snake.interval(%{game() | score: 500})
    end
  end
end
