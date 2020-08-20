if Code.ensure_loaded?(WebSockex) do
  defmodule Janus.Transport.WS.Adapter.WebSockex do
    @moduledoc """
    Adapter for [WebSockex](https://github.com/Azolo/websockex).
    """

    use Janus.Transport.WS.Adapter
    use WebSockex

    @impl true
    def connect(url, message_receiver, opts) do
      timeout = opts[:timeout] || 5000

      args = %{
        message_receiver: message_receiver,
        notify_on_connect: self()
      }

      case start_link(url, args) do
        {:ok, ws} ->
          # process have started but connection may still not be made
          # therefore wait for response from handle_connect callback
          receive do
            {:connected, _connection} ->
              {:ok, ws}
          after
            timeout ->
              # ws might still try to connect, kill so it can stop
              # websockex has no option to cancel connection (from what I've tried to find)
              Process.exit(ws, :kill)
              {:error, :connection_timeout}
          end

        error ->
          error
      end
    end

    @impl true
    def send(client, payload) do
      if Process.info(client) do
        WebSockex.send_frame(client, {:text, payload})
      else
        {:error, :connection_down}
      end
    end

    @impl true
    def disconnect(client) do
      Kernel.send(client, :disconnect)
    end

    def start_link(url, state) do
      websockex_opts = [
        extra_headers: [{"Sec-WebSocket-Protocol", "janus-protocol"}]
      ]

      WebSockex.start_link(url, __MODULE__, state, websockex_opts)
    end

    @impl true
    def handle_connect(connection, %{notify_on_connect: pid} = state) do
      notify_status(pid, {:connected, connection})
      {:ok, state}
    end

    @impl true
    def handle_disconnect(connection_status, %{message_receiver: message_receiver} = state) do
      notify_status(message_receiver, {:disconnected, connection_status})
      {:ok, state}
    end

    @impl true
    def handle_frame({_type, msg}, %{message_receiver: message_receiver} = state) do
      forward_response(message_receiver, msg)
      {:ok, state}
    end

    @impl true
    def handle_info(:disconnect, state) do
      {:close, state}
    end
  end
end
