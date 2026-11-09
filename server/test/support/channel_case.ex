defmodule BeamoWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import BeamoWeb.ChannelCase
      import Beamo.Fixtures

      @endpoint BeamoWeb.Endpoint
    end
  end

  setup tags do
    Beamo.DataCase.setup_sandbox(tags)
    :ok
  end
end
