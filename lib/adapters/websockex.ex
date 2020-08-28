if Code.ensure_loaded?(WebSockex) do
  defmodule Janus.Transport.WS.Adapters.WebSockex do
    @moduledoc """
    Adapter for [WebSockex](https://github.com/Azolo/websockex).
    """

    use Janus.Transport.WS.Adapter
    alias Janus.Transport.WS.Adapter

    defmodule WebSocketConnection do
      use WebSockex

      def send(connection, frame) do
        try do
          case WebSockex.send_frame(connection, {:text, frame}) do
            :ok -> :ok
            {:error, _reason} = error -> error
          end
        rescue
          _ -> {:error, :connection_down}
        end
      end

      def start_link(url, args) do
        opts = [extra_headers: args[:extra_headers]]
        timeout = args[:timeout]

        args = Map.put(args, :notify_on_connect, self())

        case WebSockex.start_link(url, __MODULE__, args, opts) do
          {:ok, ws} ->
            # process have started but connection may still not be established
            # therefore wait for response from handle_connect callback
            receive do
              {:connected, _connection} ->
                {:ok, ws}
            after
              timeout ->
                # close connection no matter if it is still connecting or not
                disconnect(ws)
                {:error, :connection_timeout}
            end

          {:error, _} = error ->
            error
        end
      end

      @impl true
      def handle_connect(connection, %{notify_on_connect: pid} = state) do
        Adapter.notify_status(pid, {:connected, connection})
        {:ok, state}
      end

      @impl true
      def handle_disconnect(connection_status, %{on_disconnect: on_disconnect} = state) do
        on_disconnect.(connection_status)
        {:ok, state}
      end

      @impl true
      def handle_frame({_type, frame}, %{on_receive: on_receive} = state) do
        on_receive.(frame)
        {:ok, state}
      end

      @impl true
      def handle_info(:close, state) do
        {:close, state}
      end

      def disconnect(connection) do
        Kernel.send(connection, :close)
      end
    end

    @impl Adapter
    def connect(url, receiver, opts) do
      timeout = opts[:timeout] || 5000
      extra_headers = opts[:extra_headers] || []

      args = %{
        on_receive: fn frame -> forward_frame(receiver, frame) end,
        on_disconnect: fn reason -> notify_status(receiver, {:disconnected, reason}) end,
        extra_headers: extra_headers,
        timeout: timeout
      }

      WebSocketConnection.start_link(url, args)
    end

    @impl Adapter
    def send(payload, websocket) do
      # WebSockex does not support iodata as payload
      payload = IO.iodata_to_binary(payload)
      WebSocketConnection.send(websocket, payload)
    end

    @impl Adapter
    def disconnect(websocket) do
      WebSocketConnection.disconnect(websocket)
    end
  end
end
