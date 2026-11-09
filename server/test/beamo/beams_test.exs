defmodule Beamo.BeamsTest do
  use Beamo.DataCase, async: true
  use Oban.Testing, repo: Beamo.Repo

  alias Beamo.Beams
  alias Beamo.Beams.{Beam, FanoutWorker, Recipient, ReminderWorker}
  alias Beamo.Push.SendWorker

  defp start!(user, attrs \\ %{}) do
    {:ok, beam} = Beams.start_beam(user, Map.merge(%{"category" => "drink"}, attrs))
    beam
  end

  defp pushes_to(user) do
    token = push_token(user)

    for job <- all_enqueued(worker: SendWorker),
        message <- job.args["messages"],
        message["to"] == token,
        do: message["title"]
  end

  defp recipient_ids(beam) do
    Repo.all(from r in Recipient, where: r.beam_id == ^beam.id, select: r.user_id) |> Enum.sort()
  end

  setup do
    tom = located_user(:paris, %{"name" => "Tom"})
    %{tom: tom}
  end

  describe "start_beam/2" do
    test "needs a recent location" do
      user = user_fixture()
      assert {:error, :location_required} = Beams.start_beam(user, %{"category" => "drink"})

      stale = DateTime.add(DateTime.utc_now(:second), -8, :day)
      {:ok, user} = Beamo.Accounts.update_location(user, %{"lat" => 48.0, "lng" => 2.0})
      user = user |> Ecto.Changeset.change(located_at: stale) |> Repo.update!()
      assert {:error, :location_required} = Beams.start_beam(user, %{"category" => "drink"})

      assert {:ok, %Beam{lat: 48.0}} =
               Beams.start_beam(user, %{"category" => "drink", "lat" => 48.0, "lng" => 2.0})
    end

    test "expires after the configured duration and schedules fan-out and reminder", %{tom: tom} do
      beam = start!(tom, %{"note" => " ce soir "})
      assert beam.note == "ce soir"
      assert DateTime.diff(beam.expires_at, beam.inserted_at, :minute) == Beams.duration_minutes()

      assert_enqueued(worker: FanoutWorker, args: %{"beam_id" => beam.id})

      assert_enqueued(
        worker: ReminderWorker,
        args: %{"beam_id" => beam.id},
        scheduled_at: DateTime.add(beam.expires_at, -5, :minute)
      )
    end

    test "one active beam at a time", %{tom: tom} do
      start!(tom)
      assert {:error, :already_active} = Beams.start_beam(tom, %{"category" => "coffee"})

      assert :ok = Beams.end_beam(tom)
      assert {:error, :not_found} = Beams.end_beam(tom)
      start!(tom)
    end

    test "an expired beam does not block a new one", %{tom: tom} do
      beam = start!(tom)

      Repo.update_all(where(Beam, id: ^beam.id),
        set: [expires_at: DateTime.add(DateTime.utc_now(:second), -1)]
      )

      assert %Beam{} = start!(tom)
      assert Repo.get!(Beam, beam.id).ended_at
    end

    test "rejects unknown categories and long notes", %{tom: tom} do
      assert {:error, %Ecto.Changeset{}} = Beams.start_beam(tom, %{"category" => "party"})

      assert {:error, %Ecto.Changeset{}} =
               Beams.start_beam(tom, %{
                 "category" => "drink",
                 "note" => String.duplicate("a", 141)
               })
    end
  end

  describe "fan_out/1" do
    test "notifies nearby friends only", %{tom: tom} do
      near = located_user(:montmartre)
      far = located_user(:versailles)
      stranger = located_user(:montmartre)
      befriend(tom, near)
      befriend(tom, far)

      beam = start!(tom, %{"note" => "au Perchoir"})
      assert {:ok, 1} = Beams.fan_out(beam.id)

      assert recipient_ids(beam) == [near.id]
      assert pushes_to(near) == ["Tom est dispo"]
      assert pushes_to(far) == []
      assert pushes_to(stranger) == []
      assert Repo.get!(Beam, beam.id).reach_km == 10
    end

    test "runs once per beam", %{tom: tom} do
      befriend(tom, located_user(:montmartre))
      beam = start!(tom)
      assert {:ok, 1} = Beams.fan_out(beam.id)
      assert {:ok, 0} = Beams.fan_out(beam.id)
      assert length(all_enqueued(worker: SendWorker)) == 1
    end

    test "widens the reach when nobody is around", %{tom: tom} do
      far = located_user(:versailles)
      befriend(tom, far)

      beam = start!(tom)
      assert {:ok, 1} = Beams.fan_out(beam.id)
      assert Repo.get!(Beam, beam.id).reach_km == 25
    end

    test "respects the recipient's own radius and ignores stale positions", %{tom: tom} do
      picky = located_user(:montmartre, %{"radius_mode" => "fixed", "radius_km" => 2})
      stale = located_user(:montmartre)

      Repo.update_all(where(Beamo.Accounts.User, id: ^stale.id),
        set: [located_at: DateTime.add(DateTime.utc_now(:second), -8, :day)]
      )

      befriend(tom, picky)
      befriend(tom, stale)

      beam = start!(tom)
      assert {:ok, 0} = Beams.fan_out(beam.id)
      assert Repo.get!(Beam, beam.id).reach_km == nil
    end

    test "auto reach keeps widening up to anywhere", %{tom: tom} do
      befriend(tom, located_user(:lyon))
      beam = start!(tom)
      assert {:ok, 1} = Beams.fan_out(beam.id)
      assert Repo.get!(Beam, beam.id).reach_km == nil
    end

    test "a fixed sender radius never widens", %{tom: tom} do
      tom = tom |> Ecto.Changeset.change(radius_mode: :fixed, radius_km: 10) |> Repo.update!()
      befriend(tom, located_user(:versailles))
      beam = start!(tom)
      assert {:ok, 0} = Beams.fan_out(beam.id)
    end

    test "quiet hours and mutes record the beam without pushing", %{tom: tom} do
      sleeping =
        located_user(:montmartre, %{"quiet_start" => "00:00:00", "quiet_end" => "23:59:59"})

      muting = located_user(:montmartre)
      befriend(tom, sleeping)
      befriend(tom, muting)
      :ok = Beamo.Social.mute(muting, tom.id)

      beam = start!(tom)
      assert {:ok, 2} = Beams.fan_out(beam.id)
      assert recipient_ids(beam) == Enum.sort([sleeping.id, muting.id])
      assert all_enqueued(worker: SendWorker) == []
    end

    test "one push per sender per hour", %{tom: tom} do
      lea = located_user(:montmartre)
      befriend(tom, lea)

      first = start!(tom)
      Beams.fan_out(first.id)
      :ok = Beams.end_beam(tom)
      second = start!(tom)
      assert {:ok, 1} = Beams.fan_out(second.id)

      assert pushes_to(lea) == ["Tom est dispo"]
    end

    test "caps pushes per recipient per hour", %{tom: tom} do
      lea = located_user(:montmartre)
      befriend(tom, lea)
      now = DateTime.utc_now(:second)

      for _ <- 1..5 do
        other = user_fixture()

        beam =
          Repo.insert!(%Beam{
            user_id: other.id,
            category: :drink,
            lat: 0.0,
            lng: 0.0,
            expires_at: now,
            ended_at: now
          })

        Repo.insert!(%Recipient{beam_id: beam.id, user_id: lea.id, notified_at: now})
      end

      beam = start!(tom)
      assert {:ok, 1} = Beams.fan_out(beam.id)
      assert pushes_to(lea) == []
    end
  end

  describe "replies" do
    test "a reply reaches the replier's friends and tells the original sender", %{tom: tom} do
      lea = located_user(:montmartre, %{"name" => "Léa"})
      max = located_user(:montmartre, %{"name" => "Max"})
      befriend(tom, lea)
      befriend(lea, max)

      tom_beam = start!(tom)
      Beams.fan_out(tom_beam.id)

      lea_beam = start!(lea, %{"parent_id" => tom_beam.id})
      assert lea_beam.parent_id == tom_beam.id
      assert {:ok, 2} = Beams.fan_out(lea_beam.id)

      assert pushes_to(tom) == ["Léa a répondu à ton beam"]
      assert pushes_to(max) == ["Léa est dispo"]

      assert {_beam, %{reached: 1}, [%{id: lea_id}]} = Beams.current_with_stats(tom)
      assert lea_id == lea.id
    end

    test "only a recipient can reply", %{tom: tom} do
      max = located_user(:montmartre)
      tom_beam = start!(tom)
      Beams.fan_out(tom_beam.id)

      assert {:error, :not_found} =
               Beams.start_beam(max, %{"category" => "drink", "parent_id" => tom_beam.id})
    end
  end

  describe "remind/1" do
    test "only while the beam is still on", %{tom: tom} do
      beam = start!(tom)
      assert :ok = Beams.remind(beam.id)
      assert pushes_to(tom) == ["Ton beam se termine dans 5 min"]

      :ok = Beams.end_beam(tom)
      assert :ok = Beams.remind(beam.id)
      assert length(pushes_to(tom)) == 1
    end
  end

  describe "quiet?/2" do
    test "handles windows across midnight and timezones" do
      user = %Beamo.Accounts.User{
        quiet_start: ~T[23:00:00],
        quiet_end: ~T[08:00:00],
        timezone: "Europe/Paris"
      }

      assert Beams.quiet?(user, ~U[2026-07-01 22:30:00Z])
      assert Beams.quiet?(user, ~U[2026-07-01 05:00:00Z])
      refute Beams.quiet?(user, ~U[2026-07-01 06:00:00Z])
      refute Beams.quiet?(%{user | quiet_start: nil, quiet_end: nil}, ~U[2026-07-01 22:30:00Z])
    end
  end
end
