defmodule BeamoWeb.BlockController do
  use BeamoWeb, :controller

  alias Beamo.Social
  alias BeamoWeb.UserJSON

  action_fallback BeamoWeb.FallbackController

  def index(conn, _params) do
    blocked = Social.list_blocked(conn.assigns.current_user)
    json(conn, %{blocked: Enum.map(blocked, &UserJSON.public/1)})
  end

  def create(conn, %{"user_id" => user_id}) when is_binary(user_id) do
    with :ok <- Social.block(conn.assigns.current_user, user_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def create(_conn, _params), do: {:error, :invalid}

  def delete(conn, %{"user_id" => user_id}) do
    :ok = Social.unblock(conn.assigns.current_user, user_id)
    send_resp(conn, :no_content, "")
  end
end
