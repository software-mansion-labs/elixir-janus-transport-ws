if Code.ensure_loaded?(:gun) do
  defmodule Janus.Transport.WS.Adapters.Gun do
    use GenServer

    use Janus.Transport.WS.Adapter
    alias Janus.Transport.WS.Adapter

    require Logger

    defmodule State do
      @type t :: %__MODULE__{
              connection: pid(),
              receiver: pid()
            }

      @enforce_keys [:connection, :receiver]
      defstruct @enforce_keys
    end

    @impl Adapter
    def connect(url, receiver, opts) do
      timeout = opts[:timeout] || 5000
      extra_headers = opts[:extra_headers] || []

      args = %{
        message_receiver: receiver,
        extra_headers: extra_headers
      }

      case parse_url(url) do
        {:error, _reason} = error ->
          error

        _ ->
          start_link(url, timeout, args)
      end
    end

    @impl Adapter
    def send(frame, client) do
      frame = IO.iodata_to_binary(frame)
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
      with [_protocol, _host, _port, _endpoint] = conn_params <- parse_url(url) do
        case create_ws_connection(conn_params, timeout, args) do
          {:connected, conn} ->
            {:ok, %State{connection: conn, receiver: args[:message_receiver]}}

          {:error, reason} ->
            {:stop, reason}
        end
      else
        {:error, reason} ->
          {:stop, reason}
      end
    end

    @impl GenServer
    def handle_cast(:disconnect, %State{connection: conn, receiver: receiver} = state) do
      :ok = :gun.close(conn)
      notify_status(receiver, {:disconnected, "disconnected on request"})
      {:stop, state}
    end

    def handle_cast({:send, frame}, %State{connection: conn} = state) do
      :ok = :gun.ws_send(conn, {:text, frame})
      {:noreply, state}
    end

    @impl GenServer
    def handle_info(
          {:gun_ws, _conn, _stream_ref, {:text, frame}},
          %State{receiver: receiver} = state
        ) do
      forward_frame(receiver, frame)
      {:noreply, state}
    end

    def handle_info(
          {:gun_ws, _conn, _stream_ref, {:close, _, _}},
          %State{receiver: receiver} = state
        ) do
      notify_status(receiver, {:disconnected, "remote disconnect"})
      {:noreply, state}
    end

    def handle_info(
          {:DOWN, _ref, :process, conn, reason},
          %State{connection: conn, receiver: receiver} = state
        ) do
      notify_status(receiver, {:disconnected, reason})
      {:stop, state}
    end

    # ignore protocol and try to connect without tsl
    defp create_ws_connection([_protocol, host, port, path], timeout, %{
           extra_headers: extra_headers
         }) do
      with {:ok, conn} <-
             :gun.open(String.to_charlist(host), port, %{
               transport: :tcp,
               connect_timeout: timeout
             }),
           _ref <- Process.monitor(conn),
           {:ok, _protocol} <- :gun.await_up(conn) do
        protocol = parse_sec_protocol(extra_headers)

        options =
          unless is_nil(protocol) do
            %{protocols: [protocol]}
          else
            %{}
          end

        :gun.ws_upgrade(conn, path, extra_headers, options)

        receive do
          {:gun_upgrade, conn, _stream_ref, ["websocket"], _headers} ->
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
          error
      end
    end

    def parse_sec_protocol(headers) do
      sec_protocols_keys = ["sec-websocket-protocol", "Sec-WebSocket-Protocol"]

      protocol = headers |> Enum.find(fn {key, _val} -> key in sec_protocols_keys end)

      with {_key, value} <- protocol do
        {value, :gun_ws_h}
      end
    end

    defp parse_url(url) do
      case URI.parse(url) do
        %URI{
          scheme: "ws",
          host: host,
          port: port,
          path: path
        } ->
          ["ws", host, port || 80, path || "/"]

        %URI{
          scheme: "wss"
        } ->
          Logger.error("[#{inspect(__MODULE__)}] wss schema is not supported")
          {:error, :invalid_url}

        _ ->
          {:error, :invalid_url}
      end
    end
  end
end
