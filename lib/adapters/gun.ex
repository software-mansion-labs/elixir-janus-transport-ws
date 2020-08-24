defmodule Janus.Transport.WS.Adapters.Gun do
  use Janus.Transport.WS.Adapter
  use GenServer

  @impl true
  def connect(url, receiver, opts) do
    timeout = opts[:timeout] || 5000
    args = %{
      message_receiver: receiver,
      notify_on_connect: self(),
      timeout: timeout
    }

    case start_link(url, args) do
      {:ok, ws} ->

        receive do
          {:connected, _connection} ->
            {:ok, ws}

        after
          timeout ->
            {:error, :connection_timeout}
        end



      {:error, _} = error ->
        error

    end

  end

  def start_link(url, args) do
    nil
  end

  @impl true
  def init({url, receiver, timeout}) do
    result = case parse_url(url) do
      {:error, _reason} = error ->
        error
      [protocol, host, port] = conn_params ->
        case create_ws_connection(conn_params, timeout) do

        end

    end
  end


  # ignore protocol and try to connecct without tsl
  defp create_ws_connection([_protocol, host, port], timeout) do
    with {:ok, conn} = :gun.open(host, port) do
      {:ok, _protocol} = :gun.await_up(conn)

      :gun.ws_upgrade(conn, "/", [
        {<<"Sec-WebSocket-Protocol">>, "janus-protocol"}
      ])

      receive do
        {:gun_upgrade, conn, _stream_ref, [<<"websocket">>], _headers} ->
          {:connected, conn}
        {:gun_response, _conn, _, _, _status, _} ->
          {:error, :upgrade_failed}
        {:gun_error, _conn, _, reason} ->
          {:error, reason}
      after
        timeout ->
          {:error, :connection_timeout}
      end
    else
      {:error, _} = error -> error
    end
  end

  defp parse_url(url) do
    case Regex.run(~r/(ws|wss):\/\/(.+):([0-9]+)/, url) do
      nil -> {:error, :invalid_url}
      [protocol, host, port] ->
        {port, _} = Integer.parse(port)
        [protocol, host, port]
    end
  end

end
