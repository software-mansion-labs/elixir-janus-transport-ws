defmodule WebSocket.Handler do
  @behaviour :cowboy_websocket


  @impl true
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  @impl true
  def websocket_init(state) do
    :ets.insert(:ws_test, {:client, self()})
    IO.puts "inserted new handle"
    {:ok, state}
  end

  @impl true
  def websocket_handle({:text, json}, state) do
    payload = Jason.decode!(json)

    IO.inspect payload

    {:reply, {:text, payload}, state}
  end

  @impl true
  def websocket_info(info, state) do
    IO.inspect "INFO: #{info} #{state}"
    {:reply, {:text, info}, state}
  end
end
