defmodule BeamoWeb.MuteController do
  use BeamoWeb, :controller

  alias Beamo.Social
  alias BeamoWeb.UserJSON

  action_fallback BeamoWeb.FallbackController

  def index(conn, _params) do
    muted = Social.list_muted(conn.assigns.current_user)
    json(conn, %{muted: Enum.map(muted, &UserJSON.public/1)})
  end

  def create(conn, %{"user_id" => user_id}) when is_binary(user_id) do
    with :ok <- Social.mute(conn.assigns.current_user, user_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def create(_conn, _params), do: {:error, :invalid}

  def delete(conn, %{"user_id" => user_id}) do
    :ok = Social.unmute(conn.assigns.current_user, user_id)
    send_resp(conn, :no_content, "")
  end
end
