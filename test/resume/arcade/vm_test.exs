defmodule Resume.Arcade.VmTest do
  use ExUnit.Case, async: true

  doctest Resume.Arcade.Vm

  alias Resume.Arcade.Vm

  describe "Resume.Arcade.Vm.snapshot/0" do
    test "describes the VM it runs on" do
      snapshot = Vm.snapshot()

      assert snapshot.elixir == System.version()
      assert snapshot.processes > 0
      assert snapshot.memory_bytes > 0
      assert is_binary(snapshot.architecture)
    end
  end
end
