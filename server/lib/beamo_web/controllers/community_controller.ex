defmodule BeamoWeb.CommunityController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Communities
  alias BeamoWeb.{BeamJSON, UserJSON}
  alias BeamoWeb.Plugs.RateLimit

  alias BeamoWeb.Schemas

  tags(["communities"])

  operation(:index,
    summary: "Mes communautés",
    responses: [ok: Schemas.json("Communautés", Schemas.CommunitiesResponse)] ++ Schemas.errors()
  )

  operation(:create,
    summary: "Créer une communauté avec des amis",
    request_body: Schemas.json("Communauté", Schemas.CommunityCreateRequest),
    responses: [created: Schemas.json("Créée", Schemas.Community)] ++ Schemas.errors()
  )

  operation(:show,
    summary: "Fil d'une communauté (flouté tant que je ne suis pas actif)",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [ok: Schemas.json("Communauté", Schemas.CommunityResponse)] ++ Schemas.errors()
  )

  operation(:update,
    summary: "Renommer",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    request_body: Schemas.json("Nom", Schemas.CommunityRenameRequest),
    responses: [ok: Schemas.json("Communauté", Schemas.Community)] ++ Schemas.errors()
  )

  operation(:invite,
    summary: "Inviter mes amis",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    request_body: Schemas.json("Invités", Schemas.CommunityInviteRequest),
    responses:
      [ok: Schemas.json("Invitations envoyées", Schemas.InviteResponse)] ++ Schemas.errors()
  )

  operation(:accept,
    summary: "Accepter une invitation",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [no_content: "Membre"] ++ Schemas.errors()
  )

  operation(:leave,
    summary: "Quitter ou refuser",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [no_content: "Parti"] ++ Schemas.errors()
  )

  operation(:invitations,
    summary: "Mes invitations en attente",
    responses: [ok: Schemas.json("Invitations", Schemas.InvitationsResponse)] ++ Schemas.errors()
  )

  action_fallback BeamoWeb.FallbackController

  plug RateLimit,
       [name: :community_create, by: :user, limit: 10, scale: :timer.hours(1)]
       when action == :create

  def index(conn, _params) do
    communities = Communities.list_communities(conn.assigns.current_user)

    json(conn, %{
      communities:
        Enum.map(communities, fn {c, count} -> %{id: c.id, name: c.name, member_count: count} end)
    })
  end

  def create(conn, params) do
    with {:ok, community} <- Communities.create_community(conn.assigns.current_user, params) do
      conn |> put_status(:created) |> json(%{id: community.id, name: community.name})
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, view} <- Communities.view(conn.assigns.current_user, id) do
      json(conn, %{
        id: view.community.id,
        name: view.community.name,
        active: view.active,
        active_count: view.active_count,
        members: Enum.map(view.members, &member/1)
      })
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, community} <- Communities.rename(conn.assigns.current_user, id, params) do
      json(conn, %{id: community.id, name: community.name})
    end
  end

  def invite(conn, %{"id" => id} = params) do
    with {:ok, count} <- Communities.invite(conn.assigns.current_user, id, params) do
      json(conn, %{invited: count})
    end
  end

  def accept(conn, %{"id" => id}) do
    with :ok <- Communities.accept(conn.assigns.current_user, id) do
      send_resp(conn, :no_content, "")
    end
  end

  def leave(conn, %{"id" => id}) do
    with :ok <- Communities.leave(conn.assigns.current_user, id) do
      send_resp(conn, :no_content, "")
    end
  end

  def invitations(conn, _params) do
    invitations = Communities.list_invitations(conn.assigns.current_user)

    json(conn, %{
      invitations:
        Enum.map(invitations, fn m ->
          %{
            community: %{id: m.community.id, name: m.community.name},
            invited_by: m.invited_by && UserJSON.public(m.invited_by)
          }
        end)
    })
  end

  defp member(%{member: %{status: :invited} = m}) do
    %{status: :invited, user: nil, invited_by: m.invited_by && UserJSON.public(m.invited_by)}
  end

  defp member(%{member: m, beam: beam, distance_km: distance_km}) do
    %{
      status: :member,
      user: UserJSON.public(m.user),
      beam: beam && BeamJSON.beam(beam),
      distance_km: distance_km
    }
  end
end
