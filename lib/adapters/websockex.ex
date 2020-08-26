if Code.ensure_loaded?(WebSockex) do
  defmodule Janus.Transport.WS.Adapters.WebSockex do
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

      start_link(url, timeout, args)
    end

    @impl true
    def send(client, payload) do
      try do
        case WebSockex.send_frame(client, {:text, payload}) do
          :ok -> :ok
          {:error, _reason} = error -> error
        end
      rescue
        _ -> {:error, :connection_down}
      end
    end

    @impl true
    def disconnect(client) do
      Kernel.send(client, :close)
    end

    defp start_link(url, timeout, args) do
      websockex_opts = [
        extra_headers: [{"Sec-WebSocket-Protocol", "janus-protocol"}]
      ]

      case WebSockex.start_link(url, __MODULE__, args, websockex_opts) do
        {:ok, ws} ->
          # process have started but connection may still not be established
          # therefore wait for response from handle_connect callback
          receive do
            {:connected, _connection} ->
              {:ok, ws}
          after
            timeout ->
              # close connection no matter if it is still connecting or not
              close(ws)
              {:error, :connection_timeout}
          end

        {:error, _} = error ->
          error
      end
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
    def handle_info(:close, state) do
      {:close, state}
    end

    defp close(client) do
      Kernel.send(client, :close)
    end
  end
end
