defmodule Resume.Game.Server do
  @moduledoc """
  Runs the snake game: owns the clock, takes input, and pushes HTML to the page.

  The page's JavaScript casts to this server by its registered name:

    * `"mount"` - the page is ready; render everything and start the console clock
    * `"action"` - the start / pause / resume / play again button
    * `["turn", direction]` - `"up"`, `"down"`, `"left"` or `"right"`

  After each change the server renders the page's regions with
  `Resume.Game.View` and sends only the ones whose HTML changed, as
  `%{type: "render", regions: %{id => html}}`.

  Outside the browser Popcorn's JavaScript bridge is a no-op, so the server
  runs natively in tests exactly as it does in the browser.
  """

  use GenServer

  alias Popcorn.JS
  alias Resume.Game.Snake
  alias Resume.Game.View
  alias Resume.Game.Vm

  @directions %{"up" => :up, "down" => :down, "left" => :left, "right" => :right}
  @console_interval 1_000
  @log_limit 8

  defstruct game: nil, best: 0, ticks: 0, log: [], rendered: %{}, tick_timer: nil, mounted?: false

  @type t :: %__MODULE__{
          game: Snake.t(),
          best: non_neg_integer(),
          ticks: non_neg_integer(),
          log: [String.t()],
          rendered: View.regions(),
          tick_timer: reference() | nil,
          mounted?: boolean()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl GenServer
  def init(opts) do
    {:ok, %__MODULE__{game: Snake.new(Keyword.take(opts, [:width, :height, :pick]))}}
  end

  @impl GenServer
  def handle_cast("mount", %__MODULE__{} = state) do
    state = state |> log(~s(cast "mount")) |> start_console_clock()

    # A page reload mounts again: forget what was sent so everything is re-sent.
    {:noreply, render(%{state | rendered: %{}})}
  end

  def handle_cast("action", %__MODULE__{} = state) do
    state = state |> log(~s(cast "action")) |> act() |> reschedule_tick()

    {:noreply, render(state)}
  end

  def handle_cast(["turn", name], %__MODULE__{} = state) when is_map_key(@directions, name) do
    game = Snake.turn(state.game, Map.fetch!(@directions, name))

    {:noreply, render(log(%{state | game: game}, ~s(cast ["turn", "#{name}"])))}
  end

  def handle_cast(_unknown, %__MODULE__{} = state), do: {:noreply, state}

  @impl GenServer
  def handle_info(:tick, %__MODULE__{} = state) do
    game = Snake.tick(state.game)

    state =
      %{state | ticks: state.ticks + 1, tick_timer: nil}
      |> log_outcome(game)
      |> Map.merge(%{game: game, best: max(state.best, game.score)})
      |> reschedule_tick()

    {:noreply, render(state)}
  end

  def handle_info(:refresh_console, %__MODULE__{} = state) do
    Process.send_after(self(), :refresh_console, @console_interval)

    {:noreply, render(state)}
  end

  def handle_info(_unknown, %__MODULE__{} = state), do: {:noreply, state}

  defp act(%__MODULE__{game: %Snake{status: status} = game} = state) when status in [:ready, :over] do
    %{state | game: Snake.start(game)}
  end

  defp act(%__MODULE__{game: game} = state), do: %{state | game: Snake.toggle_pause(game)}

  # One timer at most: a running game gets its next tick, anything else gets none.
  defp reschedule_tick(%__MODULE__{tick_timer: timer} = state) do
    if timer, do: Process.cancel_timer(timer)

    case state.game.status do
      :playing -> %{state | tick_timer: Process.send_after(self(), :tick, Snake.interval(state.game))}
      _stopped -> %{state | tick_timer: nil}
    end
  end

  defp start_console_clock(%__MODULE__{mounted?: true} = state), do: state

  defp start_console_clock(%__MODULE__{} = state) do
    Process.send_after(self(), :refresh_console, @console_interval)
    %{state | mounted?: true}
  end

  defp log_outcome(%__MODULE__{game: %Snake{score: before}} = state, %Snake{score: score})
       when score > before do
    log(state, "info :tick -> ate a bullet point, score #{score}")
  end

  defp log_outcome(%__MODULE__{game: %Snake{status: :playing}} = state, %Snake{status: :over}) do
    log(state, "info :tick -> game over")
  end

  defp log_outcome(%__MODULE__{} = state, %Snake{}), do: state

  defp log(%__MODULE__{log: entries} = state, entry) do
    %{state | log: Enum.take([entry | entries], @log_limit)}
  end

  defp render(%__MODULE__{rendered: rendered} = state) do
    regions = View.regions(view_assigns(state))
    changed = Map.reject(regions, fn {id, html} -> Map.get(rendered, id) == html end)

    if map_size(changed) > 0, do: JS.send(%{type: "render", regions: changed})

    %{state | rendered: regions}
  end

  defp view_assigns(%__MODULE__{} = state) do
    {:reductions, reductions} = Process.info(self(), :reductions)

    %{
      game: state.game,
      best: state.best,
      vm: Vm.snapshot(),
      server: %{pid: inspect(self()), ticks: state.ticks, reductions: reductions},
      log: state.log
    }
  end
end
