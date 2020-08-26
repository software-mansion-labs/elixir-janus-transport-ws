defmodule FakeWSAdapter do
  @moduledoc false
  # Fake websocket adapter for testing
  # it imitates reciving and sending payload messages, connecting and disconnecting by passing
  # proper options

  use Janus.Transport.WS.Adapter
  use GenServer

  def fail_message, do: "fail"

  @impl true
  def connect(url, message_receiver, opts) do
    if opts[:connection_fail] do
      {:error, "fail test"}
    else
      start_link(url, message_receiver)
    end
  end

  def start_link(url, message_receiver) do
    args = [url: url, message_receiver: message_receiver]
    GenServer.start_link(__MODULE__, args, [])
  end

  @impl true
  def send(pid, payload) do
    GenServer.call(pid, {:send, payload})
  end

  def send_to_receiver(pid, payload) do
    GenServer.cast(pid, {:send_to_receiver, payload})
  end

  def send_status_to_receiver(pid, status) do
    GenServer.cast(pid, {:notify_status, status})
  end

  @impl true
  def disconnect(pid) do
    GenServer.cast(pid, {:disconnect})
  end

  @impl true
  def init(args) do
    state = %{
      url: args[:url],
      message_receiver: args[:message_receiver]
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:send, payload}, _from, state) do
    if payload == "\"fail\"" do
      {:reply, {:error, "send error"}, state}
    else
      {:reply, :ok, state}
    end
  end

  def handle_cast({:send_to_receiver, payload}, %{message_receiver: message_receiver} = state) do
    forward_response(message_receiver, payload)
    {:noreply, state}
  end

  def handle_cast({:notify_status, status}, %{message_receiver: message_receiver} = state) do
    notify_status(message_receiver, status)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:disconnect}, %{message_receiver: message_receiver} = state) do
    notify_status(message_receiver, {:disconnected, "remote host error"})
    {:noreply, state}
  end
end
