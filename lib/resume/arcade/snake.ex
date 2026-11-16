defmodule Resume.Game.Snake do
  @moduledoc """
  The rules of the easter egg snake game, as pure functions over a struct.

  Nothing here touches the browser or a process: `Resume.Game.Server` owns the
  clock and feeds this module turns and ticks.
  """

  @type point :: {non_neg_integer(), non_neg_integer()}
  @type direction :: :up | :down | :left | :right
  @type status :: :ready | :playing | :paused | :over

  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          snake: [point()],
          direction: direction(),
          turns: [direction()],
          food: point() | nil,
          score: non_neg_integer(),
          status: status()
        }

  @enforce_keys [:width, :height, :snake, :direction, :food]
  defstruct [:width, :height, :snake, :direction, :food, turns: [], score: 0, status: :ready]

  @default_size 16
  @start_length 3
  @max_queued_turns 2
  @slowest_interval 150
  @fastest_interval 70
  @speed_up_per_point 4

  @doc """
  A new game waiting to be started: a short snake heading right from the middle
  of the board, with one piece of food.

  ## Options

    * `:width`, `:height` - board size in cells (default #{@default_size})
    * `:pick` - chooses the food cell from the free cells (default `Enum.random/1`)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    width = Keyword.get(opts, :width, @default_size)
    height = Keyword.get(opts, :height, @default_size)
    head_x = div(width, 2)
    row = div(height, 2)
    snake = for offset <- 0..(@start_length - 1), do: {head_x - offset, row}

    place_food(
      %__MODULE__{width: width, height: height, snake: snake, direction: :right, food: nil},
      Keyword.get(opts, :pick, &Enum.random/1)
    )
  end

  @doc "Starts a waiting game, or a fresh one of the same size once the game is over."
  @spec start(t(), keyword()) :: t()
  def start(game, opts \\ [])
  def start(%__MODULE__{status: :ready} = game, _opts), do: %{game | status: :playing}

  def start(%__MODULE__{status: :over} = game, opts) do
    %{new([width: game.width, height: game.height] ++ opts) | status: :playing}
  end

  def start(%__MODULE__{} = game, _opts), do: game

  @doc "Pauses a running game and resumes a paused one."
  @spec toggle_pause(t()) :: t()
  def toggle_pause(%__MODULE__{status: :playing} = game), do: %{game | status: :paused}
  def toggle_pause(%__MODULE__{status: :paused} = game), do: %{game | status: :playing}
  def toggle_pause(%__MODULE__{} = game), do: game

  @doc """
  Queues a change of direction for an upcoming tick.

  Up to #{@max_queued_turns} turns are remembered so a quick corner (two key
  presses within one tick) is not lost. A turn that would reverse the snake onto
  itself, or repeat the direction it is already about to take, is ignored.
  """
  @spec turn(t(), direction()) :: t()
  def turn(%__MODULE__{status: :playing, turns: turns} = game, direction)
      when length(turns) < @max_queued_turns do
    if allowed_turn?(heading_after_turns(game), direction) do
      %{game | turns: turns ++ [direction]}
    else
      game
    end
  end

  def turn(%__MODULE__{} = game, _direction), do: game

  @doc """
  Advances a running game by one step.

  The snake moves one cell. Reaching the food grows it by one and scores a
  point; hitting a wall or itself ends the game. `pick` chooses the next food
  cell from the free cells.
  """
  @spec tick(t(), ([point()] -> point())) :: t()
  def tick(game, pick \\ &Enum.random/1)

  def tick(%__MODULE__{status: :playing} = game, pick) do
    game = take_queued_turn(game)
    head = next_head(game)

    cond do
      head == game.food -> game |> grow(head) |> place_food(pick)
      collision?(game, head) -> %{game | status: :over}
      true -> move(game, head)
    end
  end

  def tick(%__MODULE__{} = game, _pick), do: game

  @doc "Milliseconds between ticks. The game speeds up as the score climbs."
  @spec interval(t()) :: pos_integer()
  def interval(%__MODULE__{score: score}) do
    max(@fastest_interval, @slowest_interval - score * @speed_up_per_point)
  end

  defp heading_after_turns(%__MODULE__{turns: [], direction: direction}), do: direction
  defp heading_after_turns(%__MODULE__{turns: turns}), do: List.last(turns)

  defp allowed_turn?(heading, heading), do: false
  defp allowed_turn?(heading, direction), do: direction != opposite(heading)

  defp opposite(:up), do: :down
  defp opposite(:down), do: :up
  defp opposite(:left), do: :right
  defp opposite(:right), do: :left

  defp take_queued_turn(%__MODULE__{turns: [direction | rest]} = game) do
    %{game | direction: direction, turns: rest}
  end

  defp take_queued_turn(%__MODULE__{turns: []} = game), do: game

  defp next_head(%__MODULE__{snake: [{x, y} | _body], direction: direction}) do
    case direction do
      :up -> {x, y - 1}
      :down -> {x, y + 1}
      :left -> {x - 1, y}
      :right -> {x + 1, y}
    end
  end

  # The tail cell is free to move into: it moves away on the same tick.
  defp collision?(%__MODULE__{snake: snake} = game, head) do
    off_board?(game, head) or head in Enum.drop(snake, -1)
  end

  defp off_board?(%__MODULE__{width: width, height: height}, {x, y}) do
    x < 0 or y < 0 or x >= width or y >= height
  end

  defp move(%__MODULE__{snake: snake} = game, head) do
    %{game | snake: [head | Enum.drop(snake, -1)]}
  end

  defp grow(%__MODULE__{snake: snake, score: score} = game, head) do
    %{game | snake: [head | snake], score: score + 1}
  end

  # A snake that fills the board leaves nowhere for food, which ends the game.
  defp place_food(%__MODULE__{} = game, pick) do
    case free_cells(game) do
      [] -> %{game | food: nil, status: :over}
      cells -> %{game | food: pick.(cells)}
    end
  end

  defp free_cells(%__MODULE__{width: width, height: height, snake: snake}) do
    occupied = MapSet.new(snake)
    for y <- 0..(height - 1), x <- 0..(width - 1), {x, y} not in occupied, do: {x, y}
  end
end
