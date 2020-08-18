defmodule Janus.Transport.WS.Provider do
  @moduledoc """
  Provides basic behavior for implementing websocket's client provider.

  Necessary calbacks:
   - `c:connect/3` - creates and returns websocket connection
   - `c:send_payload/2` - sends given payload in binary form via provided connection
   - `c:disconnect/1` - disconnects websocket connection on demand


  All callbacks are supposed to be synchronous.
  """

  @type connection_t :: pid()
  @type url_t :: String.t()
  @type payload_t :: binary()
  @type timeout_t :: number()
  @type message_receiver_t :: pid()
  @type status_receiver_t :: pid()

  @callback connect(url_t(), timeout_t(), message_receiver_t()) ::
              {:ok, connection_t()} | {:error, any}
  @callback send_payload(connection_t(), payload_t()) :: :ok | {:error, any}
  @callback disconnect(connection_t()) :: :ok | {:error, any}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  @doc """
  Forwards message received via websocket to message reciever previously initialized during `c:connect/3`.
  """
  @spec forward_response(message_receiver_t(), payload_t()) :: :ok
  def forward_response(message_receiver, payload) when is_pid(message_receiver) do
    send(message_receiver, {:ws_message, payload})
  end

  @doc """
  Notifies given receiver with connection status change.
  """
  @spec notify_status(status_receiver_t(), {atom(), any}) :: :ok
  def notify_status(receiver, {status, _info} = msg) when is_atom(status) and is_pid(receiver) do
    send(receiver, msg)
  end
end
