defmodule TestWebSocket.Server do
  @default_port 8081
  def get_url(port \\ @default_port) do
    "ws://localhost:#{port}/ws"
  end

  def start(port \\ @default_port) do
    cowboy_server =
      Plug.Cowboy.http(
        WebSocket.Router,
        [scheme: :http],
        TestWebSocket.Router.options(port: port)
      )

    cowboy_server =
      case cowboy_server do
        {:error, {:already_started, server}} -> server
        pid -> pid
      end

    {:ok, cowboy_server}
  end

  def shutdown() do
    Plug.Cowboy.shutdown(WebSocket.Router.HTTP)
  end
end
