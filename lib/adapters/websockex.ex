if Code.ensure_loaded?(WebSockex) do
  defmodule Janus.Transport.WS.Adapters.WebSockex do
    @moduledoc """
    Adapter for [WebSockex](https://github.com/Azolo/websockex).
    """

    use WebSockex
    use Janus.Transport.WS.Adapter
    alias Janus.Transport.WS.Adapter

    @impl Adapter
    def connect(url, message_receiver, opts) do
      timeout = opts[:timeout] || 5000
      extra_headers = opts[:extra_headers] || []

      args = %{
        message_receiver: message_receiver,
        notify_on_connect: self(),
        extra_headers: extra_headers
      }

      start_link(url, timeout, args)
    end

    @impl Adapter
    def send(client, payload) do
      # WebSockex does not support iodata as payload
      payload = IO.iodata_to_binary(payload)

      try do
        case WebSockex.send_frame(client, {:text, payload}) do
          :ok -> :ok
          {:error, _reason} = error -> error
        end
      rescue
        _ -> {:error, :connection_down}
      end
    end

    @impl Adapter
    def disconnect(client) do
      Kernel.send(client, :close)
    end

    defp start_link(url, timeout, args) do
      %{extra_headers: extra_headers} = args

      opts = [extra_headers: extra_headers]

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
              close(ws)
              {:error, :connection_timeout}
          end

        {:error, _} = error ->
          error
      end
    end

    @impl WebSockex
    def handle_connect(connection, %{notify_on_connect: pid} = state) do
      notify_status(pid, {:connected, connection})
      {:ok, state}
    end

    @impl WebSockex
    def handle_disconnect(connection_status, %{message_receiver: message_receiver} = state) do
      notify_status(message_receiver, {:disconnected, connection_status})
      {:ok, state}
    end

    @impl WebSockex
    def handle_frame({_type, frame}, %{message_receiver: message_receiver} = state) do
      forward_frame(message_receiver, frame)
      {:ok, state}
    end

    @impl WebSockex
    def handle_info(:close, state) do
      {:close, state}
    end

    defp close(client) do
      Kernel.send(client, :close)
    end
  end
end
