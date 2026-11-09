defmodule BeamoWeb.PushTokenController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Push

  alias BeamoWeb.Schemas

  tags(["push"])

  operation(:create,
    summary: "Enregistrer le token push de l'appareil",
    request_body: Schemas.json("Token", Schemas.PushTokenRequest),
    responses: [no_content: "Enregistré"] ++ Schemas.errors()
  )

  operation(:delete,
    summary: "Oublier un token push",
    parameters: [token: [in: :path, schema: %OpenApiSpex.Schema{type: :string}, required: true]],
    responses: [no_content: "Supprimé"] ++ Schemas.errors()
  )

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
