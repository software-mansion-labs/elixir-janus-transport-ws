defmodule Websocket.Server do
  def start(port \\ 8081) do
      cowboy_server = Plug.Cowboy.http(
        WebSocket.Router,
        [scheme: :http],
        WebSocket.Router.options(port: port)
      )
      %{server: cowboy_server, url: "ws://localhost:#{port}/ws"}
  end
end
