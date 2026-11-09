defmodule BeamoWeb.PushTokenController do
  use BeamoWeb, :controller

  alias Beamo.Push

  action_fallback BeamoWeb.FallbackController

  def create(conn, params) do
    with {:ok, _token} <- Push.register_token(conn.assigns.current_user, params) do
      send_resp(conn, :no_content, "")
    end
  end

  def delete(conn, %{"token" => token}) do
    :ok = Push.delete_token(conn.assigns.current_user, token)
    send_resp(conn, :no_content, "")
  end
end
