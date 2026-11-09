defmodule Beamo.Geo do
  @earth_radius_km 6371.0

  def distance_km({lat1, lng1}, {lat2, lng2}) do
    dlat = deg_to_rad(lat2 - lat1)
    dlng = deg_to_rad(lng2 - lng1)

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(deg_to_rad(lat1)) * :math.cos(deg_to_rad(lat2)) *
          :math.pow(:math.sin(dlng / 2), 2)

    2 * @earth_radius_km * :math.asin(:math.sqrt(a))
  end

  defp deg_to_rad(deg), do: deg * :math.pi() / 180
end
