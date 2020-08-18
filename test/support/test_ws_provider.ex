defmodule TestWsProivder do
  use Janus.Transport.WS.Provider
  use GenServer


  @impl true
  def connect(url, timeout, message_receiver) do
    start_link(url, timeout, message_receiver)
  end

  def start_link(url, _timeout, message_receiver) do
    GenServer.start_link(__MODULE__, [url: url, message_receiver: message_receiver],  [])
  end

  def send_message(pid, payload) do
    GenServer.call(pid, {:send, payload})
  end

  @impl true
  def disconnect(pid) do
    GenServer.cast(pid, {:disconnect})
  end

  @impl true
  def send_payload(_pid, _payload) do
    :ok
  end


  @impl true
  def init(opts) do
    state = %{
      url: opts[:url],
      message_receiver: opts[:message_reciver]
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:send, payload}, _from, state) do
    {:reply, payload, state}
  end

  @impl true
  def handle_cast({:disconnect}, %{message_receiver: message_receiver} = state) do
    notify_status(message_receiver, {:disconnected, "remote host error"})
    {:noreply, state}
  end
end
