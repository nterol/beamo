defmodule BeamoWeb.ContactController do
  use BeamoWeb, :controller

  alias Beamo.Social
  alias BeamoWeb.Plugs.RateLimit
  alias BeamoWeb.UserJSON

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
