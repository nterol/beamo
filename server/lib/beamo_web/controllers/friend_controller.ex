defmodule BeamoWeb.FriendController do
  use BeamoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Beamo.Social
  alias BeamoWeb.Plugs.RateLimit
  alias BeamoWeb.UserJSON

  alias BeamoWeb.Schemas

  tags(["friends"])

  operation(:index,
    summary: "Mes amis",
    responses: [ok: Schemas.json("Amis", Schemas.FriendsResponse)] ++ Schemas.errors()
  )

  operation(:unfriend,
    summary: "Retirer un ami",
    parameters: [user_id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [no_content: "Retiré"] ++ Schemas.errors()
  )

  operation(:requests,
    summary: "Demandes d'ami en attente",
    responses: [ok: Schemas.json("Demandes", Schemas.FriendRequestsResponse)] ++ Schemas.errors()
  )

  operation(:create_request,
    summary: "Demander quelqu'un en ami (accepte une demande croisée)",
    request_body: Schemas.json("Cible", Schemas.UserIdRequest),
    responses: [created: Schemas.json("Demande", Schemas.Friendship)] ++ Schemas.errors()
  )

  operation(:accept_request,
    summary: "Accepter une demande reçue",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [ok: Schemas.json("Amitié", Schemas.Friendship)] ++ Schemas.errors()
  )

  operation(:delete_request,
    summary: "Refuser ou annuler une demande",
    parameters: [id: [in: :path, schema: Schemas.uuid(), required: true]],
    responses: [no_content: "Supprimée"] ++ Schemas.errors()
  )

  action_fallback BeamoWeb.FallbackController

  plug RateLimit,
       [name: :friend_request, by: :user, limit: 50, scale: :timer.hours(1)]
       when action == :create_request

  def index(conn, _params) do
    friends = Social.list_friends(conn.assigns.current_user)
    json(conn, %{friends: Enum.map(friends, &UserJSON.public/1)})
  end

  def unfriend(conn, %{"user_id" => user_id}) do
    with :ok <- Social.unfriend(conn.assigns.current_user, user_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def requests(conn, _params) do
    %{incoming: incoming, outgoing: outgoing} = Social.list_requests(conn.assigns.current_user)

    json(conn, %{
      incoming: Enum.map(incoming, &%{id: &1.id, user: UserJSON.public(&1.requester)}),
      outgoing: Enum.map(outgoing, &%{id: &1.id, user: UserJSON.public(&1.addressee)})
    })
  end

  def create_request(conn, %{"user_id" => user_id}) when is_binary(user_id) do
    with {:ok, friendship} <- Social.request_friendship(conn.assigns.current_user, user_id) do
      conn |> put_status(:created) |> json(%{id: friendship.id, status: friendship.status})
    end
  end

  def create_request(_conn, _params), do: {:error, :invalid}

  def accept_request(conn, %{"id" => id}) do
    with {:ok, friendship} <- Social.accept_request(conn.assigns.current_user, id) do
      json(conn, %{id: friendship.id, status: friendship.status})
    end
  end

  def delete_request(conn, %{"id" => id}) do
    with :ok <- Social.delete_request(conn.assigns.current_user, id) do
      send_resp(conn, :no_content, "")
    end
  end
end
