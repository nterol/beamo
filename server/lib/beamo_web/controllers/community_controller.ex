defmodule BeamoWeb.CommunityController do
  use BeamoWeb, :controller

  alias Beamo.Communities
  alias BeamoWeb.{BeamJSON, UserJSON}
  alias BeamoWeb.Plugs.RateLimit

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
