defmodule Resume.Application do
  @moduledoc """
  Supervision tree for the easter egg, which runs in the browser on Popcorn.

  Nothing here is needed to build the static site. Outside the browser Popcorn
  swaps its JavaScript bridge for a no-op, so starting the app natively (tests,
  IEx) is harmless.
  """

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Task, &Resume.EasterEgg.greet/0}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Resume.Supervisor)
  end
end
