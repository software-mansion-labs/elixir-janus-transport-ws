defmodule ElixirJanusTransportWsTest do
  use ExUnit.Case
  doctest ElixirJanusTransportWs

  test "greets the world" do
    assert ElixirJanusTransportWs.hello() == :world
  end
end
