defmodule BeamoWeb.MeController do
  use BeamoWeb, :controller

  alias Beamo.Accounts
  alias BeamoWeb.UserJSON

  action_fallback BeamoWeb.FallbackController

  def show(conn, _params), do: json(conn, UserJSON.me(conn.assigns.current_user))

  def update(conn, params) do
    with {:ok, user} <- Accounts.update_settings(conn.assigns.current_user, params) do
      json(conn, UserJSON.me(user))
    end
  end

  def update_location(conn, params) do
    with {:ok, _user} <- Accounts.update_location(conn.assigns.current_user, params) do
      send_resp(conn, :no_content, "")
    end
  end

  def delete(conn, _params) do
    with {:ok, _user} <- Accounts.delete_user(conn.assigns.current_user) do
      send_resp(conn, :no_content, "")
    end
  end
end
