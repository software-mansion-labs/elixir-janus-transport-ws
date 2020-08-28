defmodule Janus.Transport.WS.Adapter do
  @moduledoc """
  This module specifies the behaviour for adapter modules communicating `Janus.Transport.WS` module
  with lower level WebSocket client (e.g. `:websockex`).

  An adapter is responsible for sending and passing WebSocket frames and notifying about connection's status change (eg. disconnected).

  Sending and receiving frames is supposed to be asynchronous.
  Frames received from websocket should be forwarded to `message_receiver` process via `forward_frame/2`.

  ## Creating custom adapter
  To implement custom adapter one should use the `Janus.Transport.WS.Adapter` and implement all callbacks.


  ## Example
  ```elixir
  defmodule CustomAdapter do
    use Janus.Transport.WS.Adapter

    @impl true
    def connect(url, receiver, opts) do
      on_receive = fn msg -> forward_message(receiver, msg) end
      ws_pid = SomeLibrary.spawn_websocket_connection(url, on_receive, opts)
      %{websocket: ws_pid, receiver: receiver}
    end

    @impl true
    def send(payload, %{websocket: pid}) do
      SomeLib.send_frame(pid, payload)
     end

    @impl true
    def disconnect(state) do
      :ok = SomeLib.disconnect(state.pid)
      notify_status(state.receiver, {:disconnected, "Disconnected request"})
    end
  end
  ```
  """

  @type websocket_t :: pid()
  @type url_t :: String.t()
  @type payload_t :: iodata()
  @type timeout_t :: number()
  @type message_receiver_t :: pid()

  @doc """
  Creates a new WebSocket connection.

  The callback should synchronously return a new connection or error on failure.

  ## Arguments
  - `url` - valid websocket url
  - `message_receiver` - pid of incoming messages and connection info recipient
  - `opts` - options specific to adapter itself

  Notice that `message_receiver` is passed only during this callback but should be used on every new websocket response and connection new status.
  """
  @callback connect(url :: url_t(), message_receiver :: message_receiver_t(), opts :: Keyword.t()) ::
              {:ok, websocket_t()} | {:error, any}

  @doc """
  Sends payload via given WebSocket.
  """
  @callback send(payload :: payload_t(), websocket :: websocket_t()) :: :ok | {:error, any}

  @doc """
  Closes the WebSocket connection.

  The callback should notify the message receiver about its status change with `{:disconnected, reason}` message.
  """
  @callback disconnect(websocket :: websocket_t()) :: :ok | {:error, any}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  @doc """
  Forwards the frame received via WebSocket to message receiver previously initialized during `c:connect/3`.
  """
  @spec forward_frame(message_receiver_t(), payload_t()) :: any()
  def forward_frame(message_receiver, frame) when is_pid(message_receiver) do
    Kernel.send(message_receiver, {:ws_frame, frame})
  end

  @doc """
  Notifies the receiver with connection's new status.

  List of currently supported statuses:
  * `{:disconnected, reason}` - used when connection has been closed from either sever or client side
  """
  @spec notify_status(message_receiver_t(), {atom(), any}) :: any()
  def notify_status(receiver, {status, _info} = msg) when is_atom(status) and is_pid(receiver) do
    Kernel.send(receiver, msg)
  end
end
