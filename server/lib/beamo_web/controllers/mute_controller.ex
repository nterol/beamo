defmodule BeamoWeb.MuteController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Social
  alias BeamoWeb.UserJSON

  alias BeamoWeb.Schemas

  tags(["mutes"])

  operation(:index,
    summary: "Amis en sourdine",
    responses: [ok: Schemas.json("Sourdines", Schemas.MutesResponse)] ++ Schemas.errors()
  )

  operation(:create,
    summary: "Mettre un ami en sourdine",
    request_body: Schemas.json("Cible", Schemas.UserIdRequest),
    responses: [no_content: "En sourdine"] ++ Schemas.errors()
  )

  operation(:delete,
    summary: "Retirer la sourdine",
    parameters: [user_id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [no_content: "Retirée"] ++ Schemas.errors()
  )

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
