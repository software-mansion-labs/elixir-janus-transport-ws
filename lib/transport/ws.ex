defmodule Janus.Transport.WS do
  @moduledoc """
  Implements `Janus.Transport` behaviour for connecting with Janus gateway via WebSocket.

  It expects the following argument to the `c:connect/1` callback:
  `{url, adapter, opts}`, where:
  * `url` - a valid URL for connecting with gateway
  * `adapter` - a module implementing behavior of `Janus.Transport.WS.Adapter`
  * `opts` - arbitrary options specific to adapters

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
    payload = Jason.encode!(payload)

    with :ok <- adapter.send(connection, payload) do
      {:ok, state}
    else
      {:error, reason} -> {:error, {:send, reason}, state}
    end
  end

  @impl true
  def handle_info({:disconnected, connection_map}, state) do
    {:stop, {:disconnected, connection_map}, state}
  end

  def handle_info({:ws_message, payload}, state) do
    with {:ok, payload_parsed} <- Jason.decode(payload) do
      {:ok, payload_parsed, state}
    else
      {:error, reason} ->
        Logger.warn(
          "[ #{__MODULE__} ] failed to parse incomming message with reason: #{inspect(reason)}"
        )

        {:stop, {:parse_failed, payload, reason}, state}
    end
  end
end
