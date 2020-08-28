if Code.ensure_loaded?(WebSockex) do
  defmodule Janus.Transport.WS.Adapters.Gun do
    use GenServer
    use Janus.Transport.WS.Adapter
    alias Janus.Transport.WS.Adapter

    @impl Adapter
    def connect(url, receiver, opts) do
      timeout = opts[:timeout] || 5000
      extra_headers = opts[:extra_headers] || []

      args = %{
        message_receiver: receiver,
        extra_headers: extra_headers
      }

      start_link(url, timeout, args)
    end

    @impl Adapter
    def send(client, frame) do
      GenServer.cast(client, {:send, frame})
    end

    @impl Adapter
    def disconnect(client) do
      GenServer.cast(client, :disconnect)
    end

    def start_link(url, timeout, args), do: do_start(:start_link, url, timeout, args)

    def start(url, timeout, args), do: do_start(:start, url, timeout, args)

    defp do_start(method, url, timeout, args) do
      apply(GenServer, method, [__MODULE__, {url, timeout, args}, []])
    end

    @impl GenServer
    def init({url, timeout, args}) do
      with [_protocol, _host, _port] = conn_params <- parse_url(url) do
        case create_ws_connection(conn_params, timeout, args) do
          {:connected, conn} ->
            {:ok, %{connection: conn, message_receiver: args[:message_receiver]}}

          {:error, reason} ->
            {:stop, reason}
        end
      else
        {:error, reason} ->
          {:stop, reason}
      end
    end

    @impl GenServer
    def handle_cast(:disconnect, %{connection: conn, message_receiver: receiver} = state) do
      :ok = :gun.close(conn)
      notify_status(receiver, {:disconnected, "disconnected on request"})
      {:stop, state}
    end

    def handle_cast({:send, frame}, %{connection: conn} = state) do
      :ok = :gun.ws_send(conn, frame)
      {:noreply, state}
    end

    @impl GenServer
    def handle_info({:gun_ws, _conn, _stream_ref, frame}, %{message_receiver: receiver} = state) do
      forward_frame(receiver, frame)
      {:noreply, state}
    end

    def handle_info(
          {:DOWN, _ref, :process, conn, reason},
          %{connection: connection, message_receiver: receiver} = state
        )
        when conn == connection do
      notify_status(receiver, {:disconnected, reason})
      {:stop, {:connection, reason}, state}
    end

    # ignore protocol and try to connect without tsl
    defp create_ws_connection([_protocol, host, port], timeout, %{extra_headers: extra_headers}) do
      with {:ok, conn} <- :gun.open(String.to_charlist(host), port, %{connect_timeout: timeout}) do
        IO.puts("CONNECTING")
        Process.monitor(conn)
        {:ok, _protocol} = :gun.await_up(conn)

        :gun.ws_upgrade(conn, "/", extra_headers)
        IO.puts("UPGRADING")

        receive do
          {:gun_upgrade, conn, _stream_ref, [<<"websocket">>], _headers} ->
            {:connected, conn}

          {:gun_response, _conn, _, _, _status, _} ->
            {:error, :upgrade_failed}

          {:gun_error, _conn, _, reason} ->
            {:error, reason}

          error ->
            {:error, error}
        end
      else
        {:error, _} = error ->
          IO.puts("ERROR CONNECTING")
          error
      end
    end

    defp parse_url(url) do
      case Regex.run(~r/(ws|wss):\/\/(.+):([0-9]+)/, url) do
        nil ->
          {:error, :invalid_url}

        [_, protocol, host, port] ->
          {port, _} = Integer.parse(port)
          [protocol, host, port]
      end
    end
  end
end
