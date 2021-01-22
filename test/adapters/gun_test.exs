defmodule Janus.Transport.WS.Adapters.GunTest do
  use ExUnit.Case

  alias Janus.Transport.WS.Adapters
  alias Janus.Transport.WS.Adapters.Gun

  @url TestWebSocket.Server.get_url()

  setup_all do
    Application.ensure_all_started(:gun)
    TestWebSocket.ClientConnection.start_link()

    {:ok, server} = TestWebSocket.Server.start()

    on_exit(fn ->
      TestWebSocket.Server.shutdown()
    end)

    %{server: server}
  end

  # testing gun adapter against cowboy websocket server
  describe "gun adapter should" do
    setup do
      {:ok, connection} = Gun.connect(@url, self(), [])

      %{connection: connection}
    end

    test "connect with working remote server" do
      assert {:ok, connection} = Gun.connect(@url, self(), [])
    end

    test "return error on invalid url" do
      assert {:error, :invalid_url} = Gun.connect("invalid_url", self(), [])
    end

    test "return error on connection failure" do
      assert {:error, :invalid_url} = Gun.connect("ws://no_server", self(), [])
    end

    test "disconnect on demand", %{connection: connection} do
      Gun.disconnect(connection)

      assert_receive {:disconnected, _}
    end

    test "send message to remote echo server and get it back", %{connection: connection} do
      :ok = Gun.send("hey", connection)

      assert_receive {:ws_frame, "hey"}
    end

    test "send disconnect message on connection end" do
      client = TestWebSocket.ClientConnection.get()
      send(client, :stop)

      assert_receive {:disconnected, _}
    end
  end

  describe "Janus.Transport.WS when used with Gun should" do
    alias Janus.Transport.WS

    setup do
      {:ok, {:state, _connection, _} = state} = WS.connect({@url, Adapters.Gun, []})
      %{state: state}
    end

    test "stop on adapter disconnected message" do
      msg = {:disconnected, "disconnect"}
      {:stop, {:disconnected, _}, _} = WS.handle_info(msg, %{})
    end

    test "send and receive back message from adapter", %{state: state} do
      payload = %{"message" => "hello"}

      assert {:ok, state} = WS.send(payload, 0, state)
      assert_receive {:ws_frame, _} = msg

      assert {:ok, ^payload, state} = WS.handle_info(msg, state)
    end

    test "not send invalid data format via adapter", %{state: state} do
      assert_raise Protocol.UndefinedError, fn ->
        WS.send([list: :type, pid: self()], 0, state)
      end
    end
  end
end
