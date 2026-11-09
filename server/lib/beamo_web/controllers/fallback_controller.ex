defmodule BeamoWeb.FallbackController do
  use BeamoWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "invalid", details: BeamoWeb.ChangesetJSON.errors(changeset)})
  end

  def call(conn, {:error, :not_found}), do: error(conn, :not_found, "not_found")
  def call(conn, {:error, :self}), do: error(conn, :unprocessable_entity, "cannot_target_self")
  def call(conn, {:error, :invalid_code}), do: error(conn, :unauthorized, "invalid_code")
  def call(conn, {:error, :invalid}), do: error(conn, :unprocessable_entity, "invalid")
  def call(conn, {:error, :too_many}), do: error(conn, :unprocessable_entity, "too_many_items")
  def call(conn, {:error, :not_friends}), do: error(conn, :unprocessable_entity, "not_friends")
  def call(conn, {:error, :already_active}), do: error(conn, :conflict, "already_active")

  def call(conn, {:error, :location_required}),
    do: error(conn, :unprocessable_entity, "location_required")

  def call(conn, {:error, :provider_error}), do: error(conn, :bad_gateway, "provider_error")

  defp error(conn, status, code), do: conn |> put_status(status) |> json(%{error: code})
end
