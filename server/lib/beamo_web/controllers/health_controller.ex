defmodule BeamoWeb.HealthController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias BeamoWeb.Schemas

  tags(["system"])

  operation(:show,
    summary: "Santé du service",
    security: [],
    responses: [ok: Schemas.json("OK", Schemas.Health)]
  )

  def show(conn, _params), do: json(conn, %{status: "ok"})
end
