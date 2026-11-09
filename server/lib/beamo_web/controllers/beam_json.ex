defmodule BeamoWeb.BeamJSON do
  alias Beamo.Beams.Beam

  def beam(%Beam{} = b) do
    %{
      id: b.id,
      category: b.category,
      note: b.note,
      parent_id: b.parent_id,
      expires_at: b.expires_at,
      inserted_at: b.inserted_at
    }
  end
end
