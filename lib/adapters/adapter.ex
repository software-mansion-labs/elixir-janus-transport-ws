defmodule Janus.Transport.WS.Adapter do
  @moduledoc """
  This module takes part in communicating `Janus.Transport.WS` module
  with lower level WebSocket client (e.g. `:websockex`).

  It is responsible for sending and passing back messages, notifying about socket status change.

  Sending messages is supposed to be synchronous while receiving is asynchronous.
  Messages received from websocket should be forwarded to `message_receiver` process via `forward_response/2`.

  ## Example
  ```elixir
  defmodule EchoAdapter do
    use Janus.Transport.WS.Adapter

    @impl true
    def connect(url, receiver, _opts) do
      Agent.start_link(fn -> receiver end)
    end

    @impl true
    def send(fake_socket, payload) do
      receiver = Agent.get(fake_socket, fn receiver -> receiver end)

      forward_response(receiver, payload)
      :ok
    end

    @impl true
    def disconnect(fake_socket) do
      receiver = Agent.get(fake_socket, fn receiver -> receiver end)
      notify_status(receiver, {:disconnected, "disconnect request"})
      :ok = Agent.stop(fake_socket)
      :ok
    end
  end

  ```
  """

  @type websocket_t :: pid()
  @type url_t :: String.t()
  @type payload_t :: binary()
  @type timeout_t :: number()
  @type message_receiver_t :: pid()
  @type status_receiver_t :: pid()

  @doc """
  Creates new websocket connection.

  The callback should synchronously return a new connection or error on failure.

  ## Arguments
  - `url` - valid websocket url
  - `message_receiver` - pid of incoming messages and status changes recipient
  - `opts` - options specific to adapter itself

  Notice that `message_receiver` is passed only during this callback but should be used on every new websocket response and status change.
  """
  @callback connect(url :: url_t(), message_receiver :: message_receiver_t(), opts :: Keyword.t()) ::
              {:ok, websocket_t()} | {:error, any}

  @doc """
  Synchronously sends payload via given websocket.

  Payload should be already encoded.
  """
  @callback send(websocket :: websocket_t(), payload :: payload_t()) :: :ok | {:error, any}

  @doc """
  Closes given socket connection on demand.

  The calblack should notify message receiver about its status change with `{:disconnected, "any arbitrary data"}` message.
  """
  @callback disconnect(websocket :: websocket_t()) :: :ok | {:error, any}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  @doc """
  Helper function to forward message received via websocket to message reciever previously initialized during `c:connect/3`.
  """
  @spec forward_response(message_receiver_t(), payload_t()) :: any()
  def forward_response(message_receiver, payload) when is_pid(message_receiver) do
    Kernel.send(message_receiver, {:ws_message, payload})
  end

  @doc """
  Helper funciton to notify given receiver with connection status change.
  """
  @spec notify_status(status_receiver_t(), {atom(), any}) :: any()
  def notify_status(receiver, {status, _info} = msg) when is_atom(status) and is_pid(receiver) do
    Kernel.send(receiver, msg)
  end
end
