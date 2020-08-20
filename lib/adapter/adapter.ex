defmodule Janus.Transport.WS.Adapter do
  @moduledoc """
  The adapter specification.

  Adapter is a module that takes part in communicating `Janus.Transport.WS` module
  with lower level ws client (e.g. `:websockex` or `:gun`), sending and passing back messages, notifying about socket status change.
  It has to implement all of given callbacks:
  - `c:Janus.Transport.WS.Adapter.connect/4`
  - `c:Janus.Transport.WS.Adapter.send_payload/2`
  - `c:Janus.Transport.WS.Adapter.disconnect/1`

  Every adapter should have its internal state as after `c:connect/3` callback
  has been called `message_receiver` will not be passed again but must be remembered.
  """

  @type connection_t :: pid()
  @type url_t :: String.t()
  @type payload_t :: binary()
  @type timeout_t :: number()
  @type message_receiver_t :: pid()
  @type status_receiver_t :: pid()

  @doc """
  Creates new websocket connection.

  The callback should be blocking and eventually return valid connection or error on failure.

  ## Arguments
  - `url` - valid websocket url
  - `message_receiver` - pid of process to which respond with messages incomming from socket and notifying about status
  - `opts` - options specific to adapter itself
  """
  @callback connect(url :: url_t(), message_receiver :: message_receiver_t(), opts :: Keyword.t()) ::
              {:ok, connection_t()} | {:error, any}

  @doc """
  Sends payload via previously created connection.

  The callback should be blocking.

  ## Arguments
  - `connection` - connection returned by `c:connect/3`
  - `payload` - encoded json payload
  """
  @callback send(connection :: connection_t(), payload :: payload_t()) :: :ok | {:error, any}

  @doc """
  Closes given connection on demand.

  The callback should be blocking.

  ## Arguments
  - `connection` - connection returned by `c:connect/3`
  """
  @callback disconnect(connection :: connection_t()) :: :ok | {:error, any}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  @doc """
  Helper function to forward message received via websocket to message reciever previously initialized during `c:connect/3`.
  """
  @spec forward_response(message_receiver_t(), payload_t()) :: :ok
  def forward_response(message_receiver, payload) when is_pid(message_receiver) do
    Kernel.send(message_receiver, {:ws_message, payload})
  end


  @doc """
  Helper funciton to notify given receiver with connection status change.
  """
  @spec notify_status(status_receiver_t(), {atom(), any}) :: :ok
  def notify_status(receiver, {status, _info} = msg) when is_atom(status) and is_pid(receiver) do
    Kernel.send(receiver, msg)
  end
end
