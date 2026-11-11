defmodule Resume.EasterEgg do
  @moduledoc """
  Feasibility spike: Elixir running in the visitor's browser.

  `greet/0` runs inside a BEAM compiled to WebAssembly and writes a message into
  the game page, proving the runtime boots and can reach the DOM.
  """

  alias Popcorn.JS

  @doc "Writes a greeting, with facts only a live VM can know, into `#status`."
  @spec greet() :: :ok | {:error, :timeout | {:js, term()}}
  def greet do
    with :ok <- JS.await_ready(),
         {:ok, _result} <- JS.run(set_status_js(), %{text: greeting()}) do
      :ok
    end
  end

  @doc "The greeting text, built from the running VM."
  @spec greeting() :: String.t()
  def greeting do
    "Hello from Elixir #{System.version()} on OTP #{System.otp_release()}. " <>
      "This message was written by process #{inspect(self())}, " <>
      "one of #{length(Process.list())} processes running in your browser."
  end

  defp set_status_js do
    """
    ({text}) => {
      document.querySelector("#status").textContent = text;
    }
    """
  end
end
