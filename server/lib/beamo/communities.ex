defmodule Beamo.Communities do
  import Ecto.Query

  alias Beamo.Accounts.User
  alias Beamo.Communities.{Community, Member}
  alias Beamo.{Beams, Push, Realtime, Repo, Social}

  @max_members 50

  def list_communities(%User{id: id}) do
    Repo.all(
      from c in Community,
        join: mine in Member,
        on: mine.community_id == c.id and mine.user_id == ^id and mine.status == :member,
        join: m in Member,
        on: m.community_id == c.id and m.status == :member,
        group_by: c.id,
        order_by: [asc: c.name],
        select: {c, count(m.id)}
    )
  end

  def co_member_ids(user_id) do
    Repo.all(
      from m in Member,
        join: mine in Member,
        on:
          mine.community_id == m.community_id and mine.user_id == ^user_id and
            mine.status == :member,
        where: m.status == :member and m.user_id != ^user_id,
        distinct: true,
        select: m.user_id
    )
  end

  defp member_ids(community_id) do
    Repo.all(
      from m in Member,
        where: m.community_id == ^community_id and m.status == :member,
        select: m.user_id
    )
  end

  defp broadcast_change(community_id) do
    Realtime.notify(member_ids(community_id), "community_changed", %{community_id: community_id})
  end

  def list_invitations(%User{id: id}) do
    Repo.all(
      from m in Member,
        where: m.user_id == ^id and m.status == :invited,
        preload: [:community, :invited_by],
        order_by: [desc: m.inserted_at]
    )
  end

  def create_community(%User{} = me, attrs) do
    ids = invitee_ids(me, attrs)

    with :ok <- check_invitees(me, ids, 1) do
      Repo.transact(fn ->
        with {:ok, community} <-
               Repo.insert(Community.changeset(%Community{created_by_id: me.id}, attrs)) do
          insert_member!(community.id, me.id, nil, :member)
          Enum.each(ids, &insert_member!(community.id, &1, me.id, :invited))
          notify_invited(community, me, ids)
          Realtime.notify(ids, "invitations_changed")
          {:ok, community}
        end
      end)
    end
  end

  def rename(%User{} = me, community_id, attrs) do
    with {:ok, community} <- get_community(me, community_id),
         {:ok, community} <- community |> Community.changeset(attrs) |> Repo.update() do
      broadcast_change(community.id)
      {:ok, community}
    end
  end

  def invite(%User{} = me, community_id, attrs) do
    with {:ok, community} <- get_community(me, community_id) do
      existing =
        Repo.all(from m in Member, where: m.community_id == ^community.id, select: m.user_id)

      case invitee_ids(me, attrs) do
        [] ->
          {:error, :invalid}

        requested ->
          case requested -- existing do
            [] -> {:ok, 0}
            ids -> do_invite(community, me, ids, length(existing))
          end
      end
    end
  end

  defp do_invite(community, me, ids, current) do
    with :ok <- check_invitees(me, ids, current) do
      Repo.transact(fn ->
        Enum.each(ids, &insert_member!(community.id, &1, me.id, :invited))
        notify_invited(community, me, ids)
        Realtime.notify(ids, "invitations_changed")
        broadcast_change(community.id)
        {:ok, length(ids)}
      end)
    end
  end

  def accept(%User{id: id}, community_id) do
    query =
      from m in Member,
        where: m.community_id == ^community_id and m.user_id == ^id and m.status == :invited

    case Repo.update_all(query, set: [status: :member, updated_at: DateTime.utc_now(:second)]) do
      {1, _} ->
        broadcast_change(community_id)
        :ok

      {0, _} ->
        {:error, :not_found}
    end
  end

  def leave(%User{id: id}, community_id) do
    Repo.transact(fn ->
      case Repo.delete_all(
             from m in Member, where: m.community_id == ^community_id and m.user_id == ^id
           ) do
        {0, _} ->
          {:error, :not_found}

        _ ->
          unless Repo.exists?(
                   from m in Member,
                     where: m.community_id == ^community_id and m.status == :member
                 ) do
            Repo.delete_all(from c in Community, where: c.id == ^community_id)
          end

          {:ok, :left}
      end
    end)
    |> case do
      {:ok, :left} ->
        broadcast_change(community_id)
        :ok

      error ->
        error
    end
  end

  def get_community(%User{id: id}, community_id) do
    query =
      from c in Community,
        join: m in Member,
        on: m.community_id == c.id and m.user_id == ^id and m.status == :member,
        where: c.id == ^community_id

    case Repo.one(query) do
      nil -> {:error, :not_found}
      community -> {:ok, community}
    end
  end

  def view(%User{} = me, community_id) do
    with {:ok, community} <- get_community(me, community_id) do
      hidden = Social.blocked_ids(me.id)

      members =
        Repo.all(
          from m in Member,
            where: m.community_id == ^community.id and m.user_id not in ^hidden,
            preload: [:user, :invited_by],
            order_by: [asc: m.inserted_at]
        )
        |> Enum.sort_by(&(&1.status != :member))

      others = for m <- members, m.status == :member, m.user_id != me.id, do: m.user_id
      active = Beams.active_beams_by_user(others)
      mine = Beams.current_beam(me.id)

      entries =
        for m <- members do
          beam = mine && active[m.user_id]

          %{
            member: m,
            beam: beam,
            distance_km: beam && Beams.approx_km({mine.lat, mine.lng}, beam)
          }
        end

      {:ok,
       %{
         community: community,
         active: not is_nil(mine),
         active_count: map_size(active),
         members: entries
       }}
    end
  end

  defp invitee_ids(%User{id: me_id}, attrs) do
    case attrs["user_ids"] do
      ids when is_list(ids) ->
        ids |> Enum.filter(&is_binary/1) |> Enum.uniq() |> List.delete(me_id)

      _ ->
        []
    end
  end

  defp check_invitees(_me, [], _current), do: {:error, :invalid}

  defp check_invitees(%User{id: id}, ids, current) do
    cond do
      current + length(ids) > @max_members -> {:error, :too_many}
      ids -- Social.friend_ids(id) != [] -> {:error, :not_friends}
      true -> :ok
    end
  end

  defp insert_member!(community_id, user_id, invited_by_id, status) do
    Repo.insert!(%Member{
      community_id: community_id,
      user_id: user_id,
      invited_by_id: invited_by_id,
      status: status
    })
  end

  defp notify_invited(community, inviter, ids) do
    {:ok, _} =
      Push.notify(ids, %{
        title: "#{inviter.name} t'invite dans « #{community.name} »",
        body: "Rejoins la communauté sur Beamo",
        data: %{"type" => "community_invite", "community_id" => community.id}
      })
  end
end
