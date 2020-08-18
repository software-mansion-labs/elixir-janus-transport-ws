defmodule ElixirJanusTransportWsTest do
  use ExUnit.Case

  alias Janus.Transport.WS

  @ws_client_provider WS.Provider.WebSockex


  describe "Janus.Transport.WS" do
    setup do
      :ets.new(:ws_test, [:named_table])
      port = 8081
      cowboy_server = Plug.Cowboy.http(
        WebSocket.Router,
        [scheme: :http],
        WebSocket.Router.options(port: port)
      )
      %{server: cowboy_server, url: "ws://localhost:#{port}/ws"}
    end


    test "connects with remote server via WebSocex", %{url: url} do
      assert {:ok, connection} = WS.connect({url, @ws_client_provider})
    end

    test "receives message sent from remote server", %{server: server, url: url} do
      {:ok, connection} = WS.connect({url, @ws_client_provider}) |> IO.inspect
      [{:client, client_handle}] = :ets.lookup(:ws_test, :client)

      send(client_handle, :fake_response)

      :erlang.trace(connection, true, :receive)

      assert_receive {:trace, ^connection, :receive, _}
    end
  end

  test "greets the world" do
  end
end
