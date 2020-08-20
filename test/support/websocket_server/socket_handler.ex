defmodule TestWebSocket.Handler do
  @behaviour :cowboy_websocket


  @impl true
  def init(request, state) do
    case :ets.whereis(:clients) do
      :undefined -> :ets.new(:clients, [:named_table, :public])
      _ref -> nil
    end

    {:cowboy_websocket, request, state}
  end

  @impl true
  def websocket_init(state) do
    TestWebSocket.ClientConnection.store(self())
    {:ok, state}
  end

  @impl true
  def websocket_handle({:text, payload}, state) do
    {:reply, {:text, payload}, state}
  end



  def websocket_info(:stop, state) do
    {:stop, state}
  end

  @impl true
  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
