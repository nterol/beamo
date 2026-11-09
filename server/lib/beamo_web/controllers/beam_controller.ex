defmodule BeamoWeb.BeamController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Beams
  alias BeamoWeb.{BeamJSON, UserJSON}
  alias BeamoWeb.Plugs.RateLimit

  alias BeamoWeb.Schemas

  tags(["beams"])

  operation(:create,
    summary: "Lancer un beam (ou répondre avec parent_id)",
    request_body: Schemas.json("Beam", Schemas.BeamCreateRequest),
    responses: [created: Schemas.json("Beam lancé", Schemas.BeamResponse)] ++ Schemas.errors()
  )

  operation(:current,
    summary: "Mon beam en cours et ses statistiques",
    responses: [ok: Schemas.json("Beam courant", Schemas.CurrentBeamResponse)] ++ Schemas.errors()
  )

  operation(:end_current,
    summary: "Arrêter mon beam",
    responses: [no_content: "Arrêté"] ++ Schemas.errors()
  )

  operation(:show,
    summary: "Un beam reçu (ouverture depuis une notification)",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [ok: Schemas.json("Beam", Schemas.ReceivedBeamResponse)] ++ Schemas.errors()
  )

  operation(:seen,
    summary: "Marquer un beam reçu comme vu",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [no_content: "Vu"] ++ Schemas.errors()
  )

  action_fallback BeamoWeb.FallbackController

  plug RateLimit,
       [name: :beam_start, by: :user, limit: 6, scale: :timer.hours(1)] when action == :create

  def create(conn, params) do
    with {:ok, beam} <- Beams.start_beam(conn.assigns.current_user, params) do
      conn |> put_status(:created) |> json(%{beam: BeamJSON.beam(beam)})
    end
  end

  def current(conn, _params) do
    case Beams.current_with_stats(conn.assigns.current_user) do
      nil ->
        json(conn, %{beam: nil})

      {beam, stats, replies} ->
        json(conn, %{
          beam: BeamJSON.beam(beam),
          reached: stats.reached,
          seen: stats.seen,
          replies: Enum.map(replies, &UserJSON.public/1)
        })
    end
  end

  def end_current(conn, _params) do
    with :ok <- Beams.end_beam(conn.assigns.current_user) do
      send_resp(conn, :no_content, "")
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, beam, distance_km} <- Beams.get_received(conn.assigns.current_user, id) do
      json(conn, %{
        beam:
          beam
          |> BeamJSON.beam()
          |> Map.merge(%{
            user: UserJSON.public(beam.user),
            active: Beams.Beam.active?(beam),
            distance_km: distance_km
          })
      })
    end
  end

  def seen(conn, %{"id" => id}) do
    with :ok <- Beams.mark_seen(conn.assigns.current_user, id) do
      send_resp(conn, :no_content, "")
    end
  end
end
