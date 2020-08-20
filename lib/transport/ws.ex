defmodule Janus.Transport.WS do
  @moduledoc """
  Implements `Janus.Transport` behaviour for connecting with Janus gateway via websocket.

  It expects the following argument to the `c:connect/1` callback:
  `{url, adapter, opts}`, where:
  * `url` - is a valid URL for connecting with gateway
  * `adapter` - is a module implementing behavior of `Janus.Transport.WS.Adapter`
  * `opts` - arbitrary options specific to adapters
  """

  @behaviour Janus.Transport

  require Record
  use Bunch

  Record.defrecordp(:state,
    connection: nil,
    adapter: nil
  )

  # Callbacks

  @impl true
  def connect({url, adapter, opts}) do
    with {:ok, connection} <- adapter.connect(url, self(), opts) do
      {:ok,
       state(
         connection: connection,
         adapter: adapter
       )}
    else
      {:error, reason} ->
        {:error, {:connection, reason}}
    end
  end

  @impl true
  def send(
        payload,
        _timeout,
        state(connection: connection, adapter: adapter) = s
      ) do
    withl encode: {:ok, payload} <- Jason.encode(payload),
          send: :ok <- adapter.send(connection, payload) do
      {:ok, s}
    else
      encode: {:error, reason} ->
        {:error, {:encode, reason}, s}

      send: {:error, reason} ->
        {:error, {:send, reason}, s}
    end
  end

  @impl true
  def handle_info({:disconnected, connection_map}, state) do
    {:stop, {:disconnected, connection_map}, state}
  end

  def handle_info({:ws_message, payload}, s) do
    with {:ok, payload_parsed} <- Jason.decode(payload) do
      {:ok, payload_parsed, s}
    else
      {:error, reason} ->
        {:stop, {:parse_failed, payload, reason}, s}
    end
  end
end
