defmodule TestWebSocket.ClientConnection do
  use Agent

  def start_link() do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def store(client) do
    Agent.update(__MODULE__, fn _ -> client end)
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end
end
