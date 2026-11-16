defmodule Resume.Game.VmTest do
  use ExUnit.Case, async: true

  doctest Resume.Game.Vm

  alias Resume.Game.Vm

  describe "Resume.Game.Vm.snapshot/0" do
    test "describes the VM it runs on" do
      snapshot = Vm.snapshot()

      assert snapshot.elixir == System.version()
      assert snapshot.processes > 0
      assert snapshot.memory_bytes > 0
      assert is_binary(snapshot.architecture)
    end
  end
end
