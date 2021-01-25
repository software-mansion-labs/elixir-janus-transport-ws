defmodule Janus.Transport.WS do
  @moduledoc """
  Implements `Janus.Transport` behaviour for connecting with Janus gateway via WebSocket.

  It expects the following argument to the `c:connect/1` callback:
  `{url, adapter, opts}`, where:
  * `url` - a valid URL for connecting with gateway
  * `adapter` - a module implementing behavior of `Janus.Transport.WS.Adapter`
  * `opts` - arbitrary options specific to adapters

  `opts` param will be extended with `extra_headers` field containing `Sec-WebSocket-Protocol` header
  necessary to connect with Janus Gateway via WebSocket, based on `admin_api?` option it is either `janus-admin-protocol` or `janus-protocol`, defaults to `janus-protocol`.

  ## Example
      # This example uses `EchoAdapter` from `Janus.Transport.WS.Adapter` example.
      iex> alias Janus.Transport.WS
      iex> {:ok, state} = WS.connect({"ws://fake_url", EchoAdapter, []})
      iex> {:ok, _} = WS.send(%{"hello" => "there"}, 0, state)
      iex> msg = receive do msg -> msg end
      iex> {:ok, %{"hello" => "there"}, state} = WS.handle_info(msg, state)
      iex> {:state, connection, EchoAdapter} = state
      iex> EchoAdapter.disconnect(connection)
      iex> msg = receive do msg -> msg end
      iex> {:stop, {:disconnected, _}, state} = WS.handle_info(msg, state)
  """

  # TODO: instead of passing sec protocol inside `extra_headers` field to the adapter add an explicit `protocols` option

  @behaviour Janus.Transport

  require Record
  require Logger

  Record.defrecordp(:state,
    connection: nil,
    adapter: nil
  )

  # Callbacks

  @impl true
  def connect({url, adapter, opts}) do
    admin_api? = opts[:admin_api?] || false

    janus_protocol =
      if admin_api? do
        {"Sec-WebSocket-Protocol", "janus-admin-protocol"}
      else
        {"Sec-WebSocket-Protocol", "janus-protocol"}
      end

    opts =
      opts
      |> Keyword.update(:extra_headers, [janus_protocol], &[janus_protocol | &1])

    with {:ok, connection} <- adapter.connect(url, self(), opts) do
      {:ok, state(connection: connection, adapter: adapter)}
    else
      {:error, reason} ->
        {:error, {:connection, reason}}
    end
  end

  @impl true
  def send(
        payload,
        _timeout,
        state(connection: connection, adapter: adapter) = state
      ) do
    frame = Jason.encode_to_iodata!(payload)

    with :ok <- adapter.send(frame, connection) do
      {:ok, state}
    else
      {:error, reason} -> {:error, {:send, reason}, state}
    end
  end

  @impl true
  def handle_info({:disconnected, connection_map}, state) do
    {:stop, {:disconnected, connection_map}, state}
  end

  def handle_info({:ws_frame, frame}, state) do
    with {:ok, payload} <- Jason.decode(frame) do
      {:ok, payload, state}
    else
      {:error, reason} ->
        Logger.warn(
          "[ #{__MODULE__} ] failed to parse incoming frame with reason: #{inspect(reason)}"
        )

        {:stop, {:parse_failed, frame, reason}, state}
    end
  end

  @impl true
  def keepalive_interval() do
    # Janus Gateway timeouts session after 60 seconds of inactivity so set keepalive interval to 30 seconds
    30_000
  end
end
