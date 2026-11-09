defmodule BeamoWeb.ApiSchema do
  alias OpenApiSpex.Schema

  def uuid, do: %Schema{type: :string, format: :uuid}
  def nullable(schema_module), do: %Schema{allOf: [schema_module], nullable: true}
  def json(description, schema), do: {description, "application/json", schema}

  def errors do
    [
      "4XX": json("Erreur client", BeamoWeb.Schemas.Error),
      "5XX": json("Erreur serveur ou fournisseur", BeamoWeb.Schemas.Error)
    ]
  end

  defmacro object(title, properties, required) do
    quote do
      require OpenApiSpex

      OpenApiSpex.schema(%{
        title: unquote(title),
        type: :object,
        additionalProperties: false,
        properties: unquote(properties),
        required: unquote(required)
      })
    end
  end
end
