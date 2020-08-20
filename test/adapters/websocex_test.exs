if Code.ensure_loaded?(WebSockex) do
  defmodule WebSocexTest do
    use ExUnit.Case

    alias Janus.Transport.WS.Adapter

    setup do
      TestWebSocket.ClientConnection.start_link()
      TestWebSocket.Server.start()
    end

    describe "websockex adapter should" do
      test "connect with working remote server", %{url: url} do
        assert {:ok, connection} = Adapter.WebSockex.connect(url, self(), [])
      end

      test "return error on invalid url", %{} do
        assert {:error, _} = Adapter.WebSockex.connect("invalid_url", self(), [])
      end

      test "return error on connection failure"do
        assert {:error, _} = Adapter.WebSockex.connect("ws://no_server", self(), [])
      end

      test "send message to remote echo server and get it back", %{url: url} do
        {:ok, connection} = Adapter.WebSockex.connect(url, self(), [])

        :ok = Adapter.WebSockex.send(connection, "hey")

        assert_receive {:ws_message, "hey"}
      end

      test "send disconnect message on connection end", %{url: url} do
        {:ok, _connection} = Adapter.WebSockex.connect(url, self(), [])
        client = TestWebSocket.ClientConnection.get()
        send client, :stop

        assert_receive {:disconnected, _}
      end

      test "return error on message send when connection is down", %{url: url} do
        {:ok, connection} = Adapter.WebSockex.connect(url, self(), [])

        client = TestWebSocket.ClientConnection.get()
        send client, :stop

        assert_receive {:disconnected, _}

        {:error, :connection_down} = Adapter.WebSockex.send(connection, "hey")
      end
    end
  end
end
