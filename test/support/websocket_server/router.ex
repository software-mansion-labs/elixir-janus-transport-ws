defmodule TestWebSocket.Router do
  use Plug.Router


  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 200, "waiting for ws")
  end

  def options(opts) do
    dispatch = [
      {:_,
       [
         {"/ws/[...]", TestWebSocket.Handler, []},
       ]}
    ]
    port = opts[:port] || 4000

    [port: port, dispatch: dispatch]
  end
end
