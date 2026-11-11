defmodule Resume.Game.Vm do
  @moduledoc """
  A snapshot of the running BEAM, for the console panel beside the game.

  In the browser these numbers describe the WebAssembly VM on the visitor's
  device; natively they describe the local VM, which keeps this testable.
  """

  @type t :: %{
          elixir: String.t(),
          otp: String.t(),
          architecture: String.t(),
          schedulers: pos_integer(),
          processes: non_neg_integer(),
          memory_bytes: non_neg_integer(),
          uptime_ms: non_neg_integer()
        }

  @spec snapshot() :: t()
  def snapshot do
    {uptime_ms, _since_last_call} = :erlang.statistics(:wall_clock)

    %{
      elixir: System.version(),
      otp: System.otp_release(),
      architecture: List.to_string(:erlang.system_info(:system_architecture)),
      schedulers: System.schedulers_online(),
      processes: :erlang.system_info(:process_count),
      memory_bytes: :erlang.memory(:total),
      uptime_ms: uptime_ms
    }
  end

  @doc """
  Formats a byte count for display.

      iex> Resume.Game.Vm.format_bytes(52_428_800)
      "50.0 MB"

      iex> Resume.Game.Vm.format_bytes(2_048)
      "2.0 KB"
  """
  @spec format_bytes(non_neg_integer()) :: String.t()
  def format_bytes(bytes) when bytes >= 1_048_576, do: "#{Float.round(bytes / 1_048_576, 1)} MB"
  def format_bytes(bytes), do: "#{Float.round(bytes / 1_024, 1)} KB"

  @doc """
  Formats a duration in milliseconds as minutes and seconds.

      iex> Resume.Game.Vm.format_uptime(83_500)
      "1m 23s"

      iex> Resume.Game.Vm.format_uptime(9_200)
      "9s"
  """
  @spec format_uptime(non_neg_integer()) :: String.t()
  def format_uptime(milliseconds) do
    case {div(milliseconds, 60_000), div(rem(milliseconds, 60_000), 1_000)} do
      {0, seconds} -> "#{seconds}s"
      {minutes, seconds} -> "#{minutes}m #{seconds}s"
    end
  end
end
