defmodule Resume.Game.View do
  @moduledoc """
  HEEx for the game page's live regions.

  The static page (`Resume.Components.game_page/1`) has one empty element per
  region. `regions/1` renders each to an HTML string keyed by that element's id,
  and `Resume.Game.Server` sends the browser whichever ones changed.
  """

  use Phoenix.Component

  alias Resume.Game.Snake
  alias Resume.Game.Vm

  @type regions :: %{String.t() => String.t()}

  @doc "Renders every region for the given assigns: `:game`, `:best`, `:vm`, `:server` and `:log`."
  @spec regions(map()) :: regions()
  def regions(assigns) do
    %{
      "board" => to_html(&board/1, assigns),
      "hud" => to_html(&hud/1, assigns),
      "action" => to_html(&action/1, assigns),
      "console" => to_html(&console/1, assigns)
    }
  end

  # Called outside a template, so the change-tracking key HEEx expects is added here.
  defp to_html(component, assigns) do
    assigns
    |> Map.put(:__changed__, nil)
    |> component.()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  attr :game, Snake, required: true

  def board(assigns) do
    assigns =
      assign(assigns,
        head: hd(assigns.game.snake),
        body: tl(assigns.game.snake),
        overlay: overlay(assigns.game)
      )

    ~H"""
    <div
      class={["grid", "is-#{@game.status}"]}
      style={"--columns: #{@game.width}; --rows: #{@game.height}"}
      role="img"
      aria-label={"Snake game board. Score #{@game.score}."}
    >
      <i :if={@game.food} class="cell food" style={cell_style(@game.food)}></i>
      <i :for={segment <- @body} class="cell snake" style={cell_style(segment)}></i>
      <i class="cell snake head" style={cell_style(@head)}></i>
      <div :if={@overlay} class="overlay">
        <strong>{@overlay.title}</strong>
        <span>{@overlay.hint}</span>
      </div>
    </div>
    """
  end

  attr :game, Snake, required: true
  attr :best, :integer, required: true

  def hud(assigns) do
    ~H"""
    <dl class="hud">
      <div>
        <dt>Score</dt>
        <dd>{@game.score}</dd>
      </div>
      <div>
        <dt>Best</dt>
        <dd>{@best}</dd>
      </div>
    </dl>
    """
  end

  attr :game, Snake, required: true

  def action(assigns) do
    ~H"""
    <button type="button" class="primary" data-event="action">{action_label(@game.status)}</button>
    """
  end

  attr :vm, :map, required: true
  attr :server, :map, required: true
  attr :log, :list, required: true

  def console(assigns) do
    ~H"""
    <dl class="stats">
      <div>
        <dt>Runtime</dt>
        <dd>Elixir {@vm.elixir} on OTP {@vm.otp}</dd>
      </div>
      <div>
        <dt>Architecture</dt>
        <dd>{@vm.architecture}</dd>
      </div>
      <div>
        <dt>Uptime</dt>
        <dd>{Vm.format_uptime(@vm.uptime_ms)}</dd>
      </div>
      <div>
        <dt>Processes</dt>
        <dd>{@vm.processes}</dd>
      </div>
      <div>
        <dt>Memory</dt>
        <dd>{Vm.format_bytes(@vm.memory_bytes)}</dd>
      </div>
      <div>
        <dt>Schedulers</dt>
        <dd>{@vm.schedulers}</dd>
      </div>
      <div>
        <dt>Game server</dt>
        <dd>{@server.pid}</dd>
      </div>
      <div>
        <dt>Ticks handled</dt>
        <dd>{@server.ticks}</dd>
      </div>
      <div>
        <dt>Reductions</dt>
        <dd>{@server.reductions}</dd>
      </div>
    </dl>
    <h3>Messages received</h3>
    <ol class="log">
      <li :for={entry <- @log}>{entry}</li>
      <li :if={@log == []} class="empty">Nothing yet.</li>
    </ol>
    """
  end

  defp cell_style({x, y}), do: "grid-area: #{y + 1} / #{x + 1}"

  defp overlay(%Snake{status: :ready}), do: %{title: "Bullet Points", hint: "Press start, then steer."}
  defp overlay(%Snake{status: :paused}), do: %{title: "Paused", hint: "Press resume to carry on."}
  defp overlay(%Snake{status: :over, score: score}), do: %{title: "Game over", hint: "You scored #{score}."}
  defp overlay(%Snake{status: :playing}), do: nil

  defp action_label(:ready), do: "Start"
  defp action_label(:playing), do: "Pause"
  defp action_label(:paused), do: "Resume"
  defp action_label(:over), do: "Play again"
end
