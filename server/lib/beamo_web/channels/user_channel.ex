defmodule BeamoWeb.UserChannel do
  use BeamoWeb, :channel

  @impl true
  def join("user:" <> user_id, _payload, %{assigns: %{user_id: user_id}} = socket) do
    Beamo.Realtime.subscribe(user_id)
    {:ok, socket}
  end

  def join(_topic, _payload, _socket), do: {:error, %{reason: "unauthorized"}}

  @impl true
  def handle_info({:realtime, event, payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end
end
