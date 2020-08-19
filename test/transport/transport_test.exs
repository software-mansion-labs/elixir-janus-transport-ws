defmodule TransportTest do
  use ExUnit.Case

  alias Janus.Transport.WS

  @adapter FakeWSAdapter
  @fake_url "ws://fake"

  @hello_message %{message: "hello"}

  setup_all do
    {:ok, {:state, connection, @adapter} = state} = WS.connect({@fake_url, @adapter, []})

    %{connection: connection, state: state}
  end



  describe "connect should" do
    test "return ok on valid connection" do
      assert {:ok, {:state, connection, @adapter}} = WS.connect({@fake_url, @adapter, []})
    end

    test "return an error on adapter failure" do
      assert {:error, {:connection, "fail test"}} = WS.connect({@fake_url, @adapter, [connection_fail: true]})
    end
  end

  describe "send should" do
    test "return ok on successfuly sent message" do
      {:ok, state} = WS.connect({@fake_url, @adapter, []})
      assert {:ok, _} = WS.send(@hello_message, 0, state)
    end

    test "return an error on invalid payload format" do
      {:ok, state} = WS.connect({@fake_url, @adapter, []})
      assert {:error, {:encode, _}, _} = WS.send(self(), 0, state)
    end

    test "return an error when adapter failed to send message" do
      {:ok, state} = WS.connect({@fake_url, @adapter, [message_fail: true]})
      assert {:error, {:send, _}, _} = WS.send(@hello_message, 0, state)
    end
  end

  describe "ws transport should" do
    test "receive messages returned by adapter" do
      {:ok, {:state, connection, @adapter}} = WS.connect({@fake_url, @adapter, []})

      @adapter.send_to_receiver(connection, "ok")
      assert_receive {:ws_message, "ok"}
    end

    test "receives disconnect event from adapter" do
      {:ok, {:state, connection, @adapter}} = WS.connect({@fake_url, @adapter, []})

      @adapter.disconnect(connection)

      assert_receive {:disconnected, _}
    end
  end
end
