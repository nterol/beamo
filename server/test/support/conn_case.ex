defmodule BeamoWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BeamoWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint BeamoWeb.Endpoint

      use BeamoWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BeamoWeb.ConnCase
      import Beamo.Fixtures
    end
  end

  setup tags do
    Beamo.DataCase.setup_sandbox(tags)
    ip = {10, :rand.uniform(255), :rand.uniform(255), :rand.uniform(255)}
    {:ok, conn: %{Phoenix.ConnTest.build_conn() | remote_ip: ip}}
  end

  def authed(conn, attrs \\ %{}) do
    {user, token} = Beamo.Fixtures.user_with_token(attrs)
    {Plug.Conn.put_req_header(conn, "authorization", "Bearer " <> token), user}
  end
end
