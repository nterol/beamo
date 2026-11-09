defmodule Beamo.Beams do
  import Ecto.Query

  alias Beamo.Accounts
  alias Beamo.Accounts.User
  alias Beamo.Beams.{Beam, FanoutWorker, Recipient, ReminderWorker}
  alias Beamo.{Geo, Push, Repo, Social}

  @location_max_age_days 7
  @auto_reach_km [10, 25, 50, nil]
  @hourly_push_cap 5
  @reminder_before_minutes 5

  @labels %{
    movie: "voir un film",
    drink: "boire un verre",
    coffee: "prendre un café",
    outdoor: "prendre l'air",
    sport: "faire du sport",
    other: "sortir"
  }

  def duration_minutes, do: Application.get_env(:beamo, :beam_duration_minutes, 120)

  def current_beam(user_id) do
    now = DateTime.utc_now(:second)

    Repo.one(
      from b in Beam,
        where: b.user_id == ^user_id and is_nil(b.ended_at) and b.expires_at > ^now
    )
  end

  def start_beam(%User{} = user, attrs) do
    now = DateTime.utc_now(:second)

    with {:ok, user} <- locate(user, attrs),
         {:ok, {lat, lng}} <- fresh_location(user, now),
         {:ok, parent} <- fetch_parent(user, attrs["parent_id"]) do
      changeset =
        Beam.create_changeset(
          %Beam{
            user_id: user.id,
            parent_id: parent && parent.id,
            lat: lat,
            lng: lng,
            expires_at: DateTime.add(now, duration_minutes(), :minute)
          },
          attrs
        )

      Repo.transact(fn ->
        close_expired(user.id, now)

        with {:ok, beam} <- Repo.insert(changeset) do
          Oban.insert!(FanoutWorker.new(%{"beam_id" => beam.id}))

          Oban.insert!(
            ReminderWorker.new(%{"beam_id" => beam.id},
              scheduled_at: DateTime.add(beam.expires_at, -@reminder_before_minutes, :minute)
            )
          )

          {:ok, beam}
        end
      end)
      |> case do
        {:error, %Ecto.Changeset{errors: errors} = changeset} ->
          if Keyword.has_key?(errors, :user_id),
            do: {:error, :already_active},
            else: {:error, changeset}

        result ->
          result
      end
    end
  end

  def end_beam(%User{id: id}) do
    now = DateTime.utc_now(:second)

    query =
      from b in Beam,
        where: b.user_id == ^id and is_nil(b.ended_at) and b.expires_at > ^now

    case Repo.update_all(query, set: [ended_at: now]) do
      {0, _} -> {:error, :not_found}
      _ -> :ok
    end
  end

  defp locate(user, %{"lat" => _, "lng" => _} = attrs), do: Accounts.update_location(user, attrs)
  defp locate(user, _attrs), do: {:ok, user}

  defp fresh_location(%User{lat: lat, lng: lng, located_at: %DateTime{} = at}, now)
       when is_float(lat) and is_float(lng) do
    if DateTime.after?(at, stale_before(now)),
      do: {:ok, {lat, lng}},
      else: {:error, :location_required}
  end

  defp fresh_location(_user, _now), do: {:error, :location_required}

  defp stale_before(now), do: DateTime.add(now, -@location_max_age_days, :day)

  defp fetch_parent(_user, nil), do: {:ok, nil}

  defp fetch_parent(%User{id: id}, parent_id) do
    query =
      from b in Beam,
        join: r in Recipient,
        on: r.beam_id == b.id and r.user_id == ^id,
        where: b.id == ^parent_id

    case Repo.one(query) do
      %Beam{} = parent -> if Beam.active?(parent), do: {:ok, parent}, else: {:error, :not_found}
      nil -> {:error, :not_found}
    end
  end

  defp close_expired(user_id, now) do
    from(b in Beam,
      where: b.user_id == ^user_id and is_nil(b.ended_at) and b.expires_at <= ^now,
      update: [set: [ended_at: field(b, :expires_at)]]
    )
    |> Repo.update_all([])
  end

  def fan_out(beam_id) do
    now = DateTime.utc_now(:second)

    with %Beam{} = beam <- Repo.get(Beam, beam_id),
         true <- Beam.active?(beam, now),
         false <- Repo.exists?(from r in Recipient, where: r.beam_id == ^beam_id) do
      do_fan_out(Repo.preload(beam, [:user, :parent]), now)
    else
      _ -> {:ok, 0}
    end
  end

  defp do_fan_out(%Beam{user: sender} = beam, now) do
    circle = Social.circle_ids(sender.id)

    parent_author =
      with %Beam{user_id: author_id} <- beam.parent,
           true <- author_id != sender.id and author_id in circle do
        Repo.get(User, author_id)
      else
        _ -> nil
      end

    candidate_ids = List.delete(circle, parent_author && parent_author.id)

    candidates =
      Repo.all(
        from u in User,
          where:
            u.id in ^candidate_ids and not is_nil(u.lat) and u.located_at > ^stale_before(now)
      )

    {reach, nearby} = within_reach(beam, sender, candidates)
    everyone = nearby ++ List.wrap(parent_author)
    pushable = pushable_ids(everyone, sender.id, now)

    rows =
      for u <- everyone do
        %{
          id: Ecto.UUID.generate(),
          beam_id: beam.id,
          user_id: u.id,
          notified_at: if(u.id in pushable, do: now),
          inserted_at: now
        }
      end

    Repo.transact(fn ->
      Repo.update_all(where(Beam, id: ^beam.id), set: [reach_km: reach])

      Repo.insert_all(Recipient, rows,
        on_conflict: :nothing,
        conflict_target: [:beam_id, :user_id]
      )

      {:ok, _} =
        Push.notify(
          Enum.map(nearby, & &1.id) |> Enum.filter(&(&1 in pushable)),
          announce(beam, sender)
        )

      if parent_author && parent_author.id in pushable,
        do: {:ok, _} = Push.notify([parent_author.id], reply(beam, sender))

      {:ok, length(everyone)}
    end)
  end

  defp within_reach(beam, sender, candidates) do
    accepting =
      for u <- candidates,
          d = Geo.distance_km({beam.lat, beam.lng}, {u.lat, u.lng}),
          u.radius_mode != :fixed or d <= u.radius_km,
          do: {u, d}

    steps = reach_steps(sender)

    Enum.reduce_while(steps, {List.last(steps), []}, fn reach, acc ->
      case for({u, d} <- accepting, is_nil(reach) or d <= reach, do: u) do
        [] -> {:cont, acc}
        found -> {:halt, {reach, found}}
      end
    end)
  end

  defp reach_steps(%User{radius_mode: :auto}), do: @auto_reach_km
  defp reach_steps(%User{radius_mode: :fixed, radius_km: radius}), do: [radius]
  defp reach_steps(%User{radius_mode: :unlimited}), do: [nil]

  defp pushable_ids([], _sender_id, _now), do: []

  defp pushable_ids(users, sender_id, now) do
    ids = Enum.map(users, & &1.id)
    hour_ago = DateTime.add(now, -1, :hour)

    muting = Social.muting_ids(ids, sender_id)

    recently_by_sender =
      Repo.all(
        from r in Recipient,
          join: b in assoc(r, :beam),
          where: r.user_id in ^ids and b.user_id == ^sender_id and r.notified_at > ^hour_ago,
          distinct: true,
          select: r.user_id
      )

    capped =
      Repo.all(
        from r in Recipient,
          where: r.user_id in ^ids and r.notified_at > ^hour_ago,
          group_by: r.user_id,
          having: count(r.id) >= ^@hourly_push_cap,
          select: r.user_id
      )

    excluded = MapSet.new(muting ++ recently_by_sender ++ capped)

    for u <- users, u.id not in excluded, not quiet?(u, now), do: u.id
  end

  def quiet?(%User{quiet_start: %Time{} = from, quiet_end: %Time{} = to, timezone: tz}, now) do
    local = now |> DateTime.shift_zone!(tz) |> DateTime.to_time()

    case Time.compare(from, to) do
      :lt -> Time.compare(local, from) != :lt and Time.compare(local, to) == :lt
      :gt -> Time.compare(local, from) != :lt or Time.compare(local, to) == :lt
      :eq -> false
    end
  end

  def quiet?(_user, _now), do: false

  defp announce(beam, sender) do
    %{
      title: "#{sender.name} est dispo",
      body: body(beam),
      data: %{"type" => "beam", "beam_id" => beam.id}
    }
  end

  defp reply(beam, sender) do
    %{
      title: "#{sender.name} a répondu à ton beam",
      body: body(beam),
      data: %{"type" => "beam_reply", "beam_id" => beam.id}
    }
  end

  defp body(beam),
    do:
      ["Pour #{@labels[beam.category]}", beam.note] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")

  def remind(beam_id) do
    with %Beam{} = beam <- Repo.get(Beam, beam_id), true <- Beam.active?(beam) do
      Push.notify([beam.user_id], %{
        title: "Ton beam se termine dans #{@reminder_before_minutes} min",
        body: "Encore un peu de temps pour te retrouver",
        data: %{"type" => "beam_ending", "beam_id" => beam.id}
      })
    end

    :ok
  end

  def feed(%User{} = me) do
    now = DateTime.utc_now(:second)
    circle = Social.circle_ids(me.id)

    active =
      Repo.all(
        from b in Beam,
          where: b.user_id in ^circle and is_nil(b.ended_at) and b.expires_at > ^now
      )
      |> Map.new(&{&1.user_id, &1})

    case current_beam(me.id) do
      nil ->
        {:inactive, map_size(active)}

      mine ->
        entries =
          Repo.all(from u in User, where: u.id in ^circle, order_by: [asc: u.name])
          |> Enum.map(fn u ->
            beam = active[u.id]
            {u, beam, beam && approx_km({mine.lat, mine.lng}, beam)}
          end)
          |> Enum.sort_by(fn {_, beam, _} -> is_nil(beam) end)

        {:active, mine, entries}
    end
  end

  def current_with_stats(%User{id: id}) do
    case current_beam(id) do
      nil ->
        nil

      beam ->
        stats =
          Repo.one(
            from r in Recipient,
              where: r.beam_id == ^beam.id,
              select: %{reached: count(r.id), seen: filter(count(r.id), not is_nil(r.seen_at))}
          )

        replies =
          Repo.all(
            from b in Beam,
              join: u in assoc(b, :user),
              where: b.parent_id == ^beam.id,
              order_by: b.inserted_at,
              select: u
          )

        {beam, stats, replies}
    end
  end

  def get_received(%User{} = me, beam_id) do
    query =
      from b in Beam,
        join: r in Recipient,
        on: r.beam_id == b.id and r.user_id == ^me.id,
        where: b.id == ^beam_id,
        preload: [:user]

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      beam ->
        distance = if me.lat && me.lng, do: approx_km({me.lat, me.lng}, beam)
        {:ok, beam, distance}
    end
  end

  def mark_seen(%User{id: id}, beam_id) do
    case Repo.get_by(Recipient, beam_id: beam_id, user_id: id) do
      nil ->
        {:error, :not_found}

      %Recipient{seen_at: nil} = recipient ->
        recipient |> Ecto.Changeset.change(seen_at: DateTime.utc_now(:second)) |> Repo.update!()
        :ok

      _seen ->
        :ok
    end
  end

  defp approx_km(point, beam), do: max(1, round(Geo.distance_km(point, {beam.lat, beam.lng})))
end
