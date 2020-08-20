defmodule TestWebSocket.Server do


  def get_url(port) do
    "ws://localhost:#{port}/ws"
  end



  def start(port \\ 8081) do
      cowboy_server = Plug.Cowboy.http(
        WebSocket.Router,
        [scheme: :http],
        TestWebSocket.Router.options(port: port)
      )
      cowboy_server = case cowboy_server do
        {:error, {:already_started, server}} -> server
        pid -> pid
      end
      %{server: cowboy_server, url: get_url(port)}
  end
end
