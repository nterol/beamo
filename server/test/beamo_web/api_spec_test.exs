defmodule BeamoWeb.ApiSpecTest do
  use BeamoWeb.ConnCase, async: true

  test "every API route is documented" do
    documented =
      for {path, item} <- BeamoWeb.ApiSpec.spec().paths,
          {verb, %OpenApiSpex.Operation{}} <- Map.from_struct(item),
          do: {verb, path}

    routes =
      for %{path: "/api/" <> _ = path, verb: verb, plug: plug} <- BeamoWeb.Router.__routes__(),
          plug != OpenApiSpex.Plug.RenderSpec,
          do: {verb, String.replace(path, ~r/:(\w+)/, "{\\1}")}

    assert length(routes) > 30
    assert Enum.sort(routes) -- Enum.sort(documented) == []
  end

  test "serves the spec and a health check", %{conn: conn} do
    assert %{"info" => %{"title" => "Beamo API"}} =
             json_response(get(conn, ~p"/api/openapi"), 200)

    assert %{"status" => "ok"} = json_response(get(conn, ~p"/api/health"), 200)
  end
end
