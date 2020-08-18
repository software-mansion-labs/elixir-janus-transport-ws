defmodule WebSocket.Router do
  use Plug.Router

  # plug Plug.Parsers,
  #   parsers: [:json],
  #   pass: ["application/json"],
  #   json_decoder: Jason


  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 200, "waiting for ws")
  end

  def options(opts) do
    dispatch = [
      {:_,
       [
         {"/ws/[...]", WebSocket.Handler, []},
       ]}
    ]
    port = opts[:port] || 4000

    [port: port, dispatch: dispatch]
  end
end
