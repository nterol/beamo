defmodule BeamoWeb.UserSocket do
  use Phoenix.Socket

  channel "user:*", BeamoWeb.UserChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Beamo.Accounts.authenticate(token) do
      {:ok, user, session} -> {:ok, assign(socket, user_id: user.id, session_id: session.id)}
      :error -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: socket_id(socket.assigns.session_id)

  def socket_id(session_id), do: "session_socket:#{session_id}"

  def disconnect(session_id),
    do: BeamoWeb.Endpoint.broadcast(socket_id(session_id), "disconnect", %{})
end
