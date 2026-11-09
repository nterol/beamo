defmodule BeamoWeb.ContactController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Social
  alias BeamoWeb.Plugs.RateLimit
  alias BeamoWeb.UserJSON

  alias BeamoWeb.Schemas

  tags(["contacts"])

  operation(:match,
    summary: "Retrouver mes contacts inscrits",
    request_body: Schemas.json("Hashes", Schemas.ContactMatchRequest),
    responses:
      [ok: Schemas.json("Correspondances", Schemas.ContactMatchResponse)] ++ Schemas.errors()
  )

  action_fallback BeamoWeb.FallbackController

  plug RateLimit, name: :contact_match, by: :user, limit: 10, scale: :timer.hours(1)

  def match(conn, %{"hashes" => hashes}) do
    with {:ok, matches} <- Social.match_contacts(conn.assigns.current_user, hashes) do
      json(conn, %{
        matches:
          Enum.map(matches, fn {user, relation} ->
            Map.put(UserJSON.public(user), :relation, relation)
          end)
      })
    end
  end

  def match(_conn, _params), do: {:error, :invalid}
end
