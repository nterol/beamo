defmodule BeamoWeb.MeController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Accounts
  alias BeamoWeb.UserJSON

  alias BeamoWeb.Schemas

  tags(["me"])

  operation(:show,
    summary: "Mon profil et mes réglages",
    responses: [ok: Schemas.json("Profil", Schemas.Me)] ++ Schemas.errors()
  )

  operation(:update,
    summary: "Modifier mon profil et mes réglages",
    request_body: Schemas.json("Champs à modifier", Schemas.MeUpdateRequest),
    responses: [ok: Schemas.json("Profil", Schemas.Me)] ++ Schemas.errors()
  )

  operation(:update_location,
    summary: "Mettre à jour ma position (arrondie côté serveur)",
    request_body: Schemas.json("Position", Schemas.LocationRequest),
    responses: [no_content: "Position enregistrée"] ++ Schemas.errors()
  )

  operation(:delete,
    summary: "Supprimer mon compte et toutes mes données",
    responses: [no_content: "Compte supprimé"] ++ Schemas.errors()
  )

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
    user = conn.assigns.current_user
    session_ids = Accounts.session_ids(user)

    with {:ok, _user} <- Accounts.delete_user(user) do
      Enum.each(session_ids, &BeamoWeb.UserSocket.disconnect/1)
      send_resp(conn, :no_content, "")
    end
  end
end
