defmodule BeamoWeb.BeamController do
  use BeamoWeb, :controller

  alias Beamo.Beams
  alias BeamoWeb.{BeamJSON, UserJSON}
  alias BeamoWeb.Plugs.RateLimit

  action_fallback BeamoWeb.FallbackController

  plug RateLimit,
       [name: :beam_start, by: :user, limit: 6, scale: :timer.hours(1)] when action == :create

  def create(conn, params) do
    with {:ok, beam} <- Beams.start_beam(conn.assigns.current_user, params) do
      conn |> put_status(:created) |> json(%{beam: BeamJSON.beam(beam)})
    end
  end

  def current(conn, _params) do
    case Beams.current_with_stats(conn.assigns.current_user) do
      nil ->
        json(conn, %{beam: nil})

      {beam, stats, replies} ->
        json(conn, %{
          beam: BeamJSON.beam(beam),
          reached: stats.reached,
          seen: stats.seen,
          replies: Enum.map(replies, &UserJSON.public/1)
        })
    end
  end

  def end_current(conn, _params) do
    with :ok <- Beams.end_beam(conn.assigns.current_user) do
      send_resp(conn, :no_content, "")
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, beam, distance_km} <- Beams.get_received(conn.assigns.current_user, id) do
      json(conn, %{
        beam:
          beam
          |> BeamJSON.beam()
          |> Map.merge(%{
            user: UserJSON.public(beam.user),
            active: Beams.Beam.active?(beam),
            distance_km: distance_km
          })
      })
    end
  end

  def seen(conn, %{"id" => id}) do
    with :ok <- Beams.mark_seen(conn.assigns.current_user, id) do
      send_resp(conn, :no_content, "")
    end
  end
end
