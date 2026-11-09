defmodule Beamo.Social do
  import Ecto.Query

  alias Beamo.Accounts.User
  alias Beamo.Repo
  alias Beamo.Social.{Block, Friendship, Mute}

  @max_contact_hashes 2000

  def list_friends(%User{id: id}) do
    Repo.all(
      from u in User,
        join: f in Friendship,
        on:
          (f.requester_id == ^id and f.addressee_id == u.id) or
            (f.addressee_id == ^id and f.requester_id == u.id),
        where: f.status == :accepted,
        order_by: [asc: u.name]
    )
  end

  def friend_ids(user_id) do
    Repo.all(
      from f in Friendship,
        where:
          f.status == :accepted and (f.requester_id == ^user_id or f.addressee_id == ^user_id),
        select:
          type(
            fragment(
              "CASE WHEN ? = ? THEN ? ELSE ? END",
              f.requester_id,
              type(^user_id, :binary_id),
              f.addressee_id,
              f.requester_id
            ),
            :binary_id
          )
    )
  end

  def circle_ids(user_id), do: friend_ids(user_id)

  def friends?(a_id, b_id) do
    Repo.exists?(pair_query(a_id, b_id) |> where(status: :accepted))
  end

  def list_requests(%User{id: id}) do
    requests =
      Repo.all(
        from f in Friendship,
          where: f.status == :pending and (f.requester_id == ^id or f.addressee_id == ^id),
          preload: [:requester, :addressee],
          order_by: [desc: f.inserted_at]
      )

    %{
      incoming: Enum.filter(requests, &(&1.addressee_id == id)),
      outgoing: Enum.filter(requests, &(&1.requester_id == id))
    }
  end

  def request_friendship(%User{id: id}, id), do: {:error, :self}

  def request_friendship(%User{id: id}, target_id) do
    cond do
      blocked_between?(id, target_id) ->
        {:error, :not_found}

      existing = Repo.one(pair_query(id, target_id)) ->
        case existing do
          %{status: :pending, addressee_id: ^id} -> accept(existing)
          _ -> {:ok, existing}
        end

      true ->
        case Repo.insert(Friendship.request_changeset(id, target_id)) do
          {:ok, friendship} ->
            {:ok, friendship}

          {:error, %Ecto.Changeset{errors: errors} = changeset} ->
            if Keyword.has_key?(errors, :addressee_id),
              do: {:error, :not_found},
              else: {:error, changeset}
        end
    end
  end

  def accept_request(%User{id: id}, friendship_id) do
    case Repo.get_by(Friendship, id: friendship_id, addressee_id: id, status: :pending) do
      nil -> {:error, :not_found}
      friendship -> accept(friendship)
    end
  end

  defp accept(friendship),
    do: friendship |> Ecto.Changeset.change(status: :accepted) |> Repo.update()

  def delete_request(%User{id: id}, friendship_id) do
    query =
      from f in Friendship,
        where: f.id == ^friendship_id and f.status == :pending,
        where: f.requester_id == ^id or f.addressee_id == ^id

    case Repo.delete_all(query) do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  def unfriend(%User{id: id}, other_id) do
    case Repo.delete_all(pair_query(id, other_id) |> where(status: :accepted)) do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  defp pair_query(a_id, b_id) do
    from f in Friendship,
      where:
        (f.requester_id == ^a_id and f.addressee_id == ^b_id) or
          (f.requester_id == ^b_id and f.addressee_id == ^a_id)
  end

  def block(%User{id: id}, id), do: {:error, :self}

  def block(%User{id: id}, target_id) do
    Repo.transact(fn ->
      Repo.delete_all(pair_query(id, target_id))

      %Block{blocker_id: id, blocked_id: target_id}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.foreign_key_constraint(:blocked_id)
      |> Repo.insert(on_conflict: :nothing, conflict_target: [:blocker_id, :blocked_id])
      |> case do
        {:ok, _} -> {:ok, :blocked}
        {:error, _} -> {:error, :not_found}
      end
    end)
    |> case do
      {:ok, :blocked} -> :ok
      error -> error
    end
  end

  def unblock(%User{id: id}, target_id) do
    Repo.delete_all(from b in Block, where: b.blocker_id == ^id and b.blocked_id == ^target_id)
    :ok
  end

  def list_blocked(%User{id: id}) do
    Repo.all(
      from u in User,
        join: b in Block,
        on: b.blocked_id == u.id,
        where: b.blocker_id == ^id,
        order_by: [desc: b.inserted_at]
    )
  end

  def blocked_ids(user_id) do
    Repo.all(
      from b in Block,
        where: b.blocker_id == ^user_id or b.blocked_id == ^user_id,
        select:
          type(
            fragment(
              "CASE WHEN ? = ? THEN ? ELSE ? END",
              b.blocker_id,
              type(^user_id, :binary_id),
              b.blocked_id,
              b.blocker_id
            ),
            :binary_id
          )
    )
  end

  def blocked_between?(a_id, b_id) do
    Repo.exists?(
      from b in Block,
        where:
          (b.blocker_id == ^a_id and b.blocked_id == ^b_id) or
            (b.blocker_id == ^b_id and b.blocked_id == ^a_id)
    )
  end

  def mute(%User{id: id}, id), do: {:error, :self}

  def mute(%User{id: id}, target_id) do
    %Mute{user_id: id, muted_id: target_id}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.foreign_key_constraint(:muted_id)
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :muted_id])
    |> case do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :not_found}
    end
  end

  def unmute(%User{id: id}, target_id) do
    Repo.delete_all(from m in Mute, where: m.user_id == ^id and m.muted_id == ^target_id)
    :ok
  end

  def list_muted(%User{id: id}) do
    Repo.all(from u in User, join: m in Mute, on: m.muted_id == u.id, where: m.user_id == ^id)
  end

  def muting_ids(user_ids, muted_id) do
    Repo.all(
      from m in Mute, where: m.user_id in ^user_ids and m.muted_id == ^muted_id, select: m.user_id
    )
  end

  def match_contacts(%User{}, hashes) when length(hashes) > @max_contact_hashes,
    do: {:error, :too_many}

  def match_contacts(%User{id: id}, hashes) when is_list(hashes) do
    hashes = hashes |> Enum.filter(&is_binary/1) |> Enum.map(&String.downcase/1) |> Enum.uniq()

    rows =
      Repo.all(
        from u in User,
          left_join: f in Friendship,
          on:
            (f.requester_id == ^id and f.addressee_id == u.id) or
              (f.addressee_id == ^id and f.requester_id == u.id),
          left_join: b in Block,
          on:
            (b.blocker_id == ^id and b.blocked_id == u.id) or
              (b.blocked_id == ^id and b.blocker_id == u.id),
          where: u.phone_hash in ^hashes and u.id != ^id and is_nil(b.id),
          select: {u, f}
      )

    {:ok, Enum.map(rows, fn {user, friendship} -> {user, relation(friendship, id)} end)}
  end

  def match_contacts(_user, _hashes), do: {:error, :invalid}

  defp relation(nil, _id), do: :none
  defp relation(%Friendship{status: :accepted}, _id), do: :friend
  defp relation(%Friendship{requester_id: id}, id), do: :outgoing
  defp relation(%Friendship{}, _id), do: :incoming
end
