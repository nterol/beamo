defmodule BeamoWeb.FeedController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Beams
  alias BeamoWeb.{BeamJSON, UserJSON}

  alias BeamoWeb.Schemas

  tags(["beams"])

  operation(:index,
    summary: "Fil principal (flouté tant que je ne suis pas actif)",
    responses: [ok: Schemas.json("Fil", Schemas.FeedResponse)] ++ Schemas.errors()
  )

  def index(conn, _params) do
    case Beams.feed(conn.assigns.current_user) do
      {:inactive, active_count} ->
        json(conn, %{active: false, active_count: active_count})

      {:active, mine, entries} ->
        json(conn, %{
          active: true,
          beam: BeamJSON.beam(mine),
          friends:
            Enum.map(entries, fn {user, beam, distance_km} ->
              %{
                user: UserJSON.public(user),
                beam: beam && BeamJSON.beam(beam),
                distance_km: distance_km
              }
            end)
        })
    end
  end
end
