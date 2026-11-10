defmodule ResumeTest do
  use ExUnit.Case
  doctest Resume

  test "greets the world" do
    assert Resume.hello() == :world
  end
end
