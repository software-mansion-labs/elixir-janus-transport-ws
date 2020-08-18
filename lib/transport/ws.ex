defmodule Janus.Transport.WS do
  @moduledoc """
  Implements connecting to the Janus gateway over Web Socket.
  It expects the following argument to the `c:connect/1` callback:
  `{url, ws_provider}`, where:
  * `url` - is a valid URL for ws connection to the gateway
  * `ws_proivder` - is a module implementing behavior of `Janus.Transport.WS.Provider`
  """

  @behaviour Janus.Transport

  require Record
  use Bunch


  Record.defrecordp(:state,
    connection: nil,
    ws_provider: nil
  )

  # Callbacks

  @impl true
  def connect({url, ws_provider}) do
    with {:ok, connection} <- ws_provider.connect(url, 5000, self()) do
      {:ok,
       state(
         connection: connection,
         ws_provider: ws_provider
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
        state(connection: connection, ws_provider: ws_provider) = s
      ) do
    withl encode: {:ok, payload} <- Jason.encode(payload),
          send: :ok <- ws_provider.send(connection, payload) do
      {:ok, s}
    else
      encode: {:error, reason} ->
        {:error, {:encode, reason}, s}

      send: {:error, reason} ->
        {:error, {:send, reason}, s}
    end
  end


  # Should be sent by ws connection back
  @impl true
  def handle_info({:response, payload}, s) do
    with {:ok, payload_parsed} <- Jason.decode(payload) do
      {:ok, payload_parsed, s}
    else
      {:error, reason} ->
        {:stop, {:parse_failed, payload, reason}, s}
    end
  end
end
