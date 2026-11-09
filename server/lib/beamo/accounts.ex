defmodule Beamo.Accounts do
  import Ecto.Query

  alias Beamo.Accounts.{OTP, Session, User}
  alias Beamo.Repo

  @session_ttl_days 90
  @session_refresh_days 60

  def start_verification(phone), do: OTP.start(phone)

  def verify_and_login(phone, code) do
    with :ok <- OTP.check(phone, code),
         {:ok, user} <- get_or_register_user(phone) do
      {:ok, create_session(user), user, is_nil(user.name)}
    end
  end

  defp get_or_register_user(phone) do
    case Repo.get_by(User, phone: phone) do
      nil ->
        %User{}
        |> User.registration_changeset(%{phone: phone})
        |> Repo.insert(
          on_conflict: {:replace, [:updated_at]},
          conflict_target: :phone,
          returning: true
        )

      user ->
        {:ok, user}
    end
  end

  defp create_session(user) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    Repo.insert!(%Session{
      user_id: user.id,
      token_hash: hash_token(token),
      expires_at: DateTime.add(DateTime.utc_now(:second), @session_ttl_days, :day)
    })

    token
  end

  def authenticate(token) when is_binary(token) do
    now = DateTime.utc_now(:second)

    query =
      from s in Session,
        join: u in assoc(s, :user),
        where: s.token_hash == ^hash_token(token) and s.expires_at > ^now,
        select: {u, s}

    case Repo.one(query) do
      nil ->
        :error

      {user, session} ->
        if DateTime.diff(session.expires_at, now, :day) < @session_refresh_days do
          Repo.update_all(where(Session, id: ^session.id),
            set: [expires_at: DateTime.add(now, @session_ttl_days, :day)]
          )
        end

        {:ok, user, session}
    end
  end

  def authenticate(_), do: :error

  def delete_session(%Session{id: id}), do: Repo.delete_all(where(Session, id: ^id))

  def get_user(id), do: Repo.get(User, id)

  def update_settings(user, attrs), do: user |> User.settings_changeset(attrs) |> Repo.update()

  def update_location(user, attrs), do: user |> User.location_changeset(attrs) |> Repo.update()

  def delete_user(user), do: Repo.delete(user)

  defp hash_token(token), do: :crypto.hash(:sha256, token)
end
