defmodule TransportTest do
  use ExUnit.Case

  alias Janus.Transport.WS

  @adapter FakeWSAdapter
  @fail_message FakeWSAdapter.fail_message()
  @fake_url "ws://fake"

  @hello_message %{message: "hello"}

  describe "connect should" do
    test "return ok on valid connection" do
      assert {:ok, {:state, connection, @adapter}} = WS.connect({@fake_url, @adapter, []})
    end

    test "return an error on adapter failure" do
      assert {:error, {:connection, "fail test"}} =
               WS.connect({@fake_url, @adapter, [connection_fail: true]})
    end
  end

  describe "send should" do
    setup do
      {:ok, state} = WS.connect({@fake_url, @adapter, []})
      %{state: state}
    end

    test "return ok on successfuly sent message", %{state: state} do
      assert {:ok, _} = WS.send(@hello_message, 0, state)
    end

    test "return an error on invalid payload format", %{state: state} do
      assert_raise Protocol.UndefinedError, fn ->
        WS.send(self(), 0, state)
      end
    end

    test "return an error when adapter failed to send message", %{state: state} do
      assert {:error, {:send, _}, _} = WS.send(@fail_message, 0, state)
    end
  end

  describe "ws transport should" do
    setup do
      {:ok, {:state, connection, @adapter}} = WS.connect({@fake_url, @adapter, []})
      %{conn: connection}
    end

    test "receive messages returned by adapter", %{conn: connection} do
      @adapter.send_to_receiver(connection, "ok")
      assert_receive {:ws_message, "ok"}
    end

    test "receives disconnect event from adapter", %{conn: connection} do
      @adapter.disconnect(connection)
      assert_receive {:disconnected, _}
    end
  end
end
