defmodule Beamo.Repo.Migrations.AddRadiusMode do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :radius_mode, :string, null: false, default: "auto"
      modify :radius_km, :integer, default: nil, from: {:integer, default: 10}
    end

    execute "UPDATE users SET radius_km = NULL", ""
  end
end
