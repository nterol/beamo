defmodule BeamoWeb.ApiSpec do
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, SecurityScheme, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [%Server{url: "/"}],
      info: %Info{title: "Beamo API", version: "1.0.0"},
      paths: Paths.from_router(BeamoWeb.Router),
      components: %Components{
        securitySchemes: %{"bearer" => %SecurityScheme{type: "http", scheme: "bearer"}}
      },
      security: [%{"bearer" => []}]
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
