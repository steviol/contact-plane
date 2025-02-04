defmodule ContactPlaneTest do
  use ExUnit.Case
  doctest ContactPlane

  test "greets the world" do
    assert ContactPlane.hello() == :world
  end
end
