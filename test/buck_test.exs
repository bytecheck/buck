defmodule BuckTest do
  use ExUnit.Case
  doctest Buck

  test "greets the world" do
    assert Buck.hello() == :world
  end
end
