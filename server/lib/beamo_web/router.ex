defmodule BeamoWeb.Router do
  use BeamoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: BeamoWeb.ApiSpec
  end

  pipeline :authenticated do
    plug BeamoWeb.Plugs.Auth
  end

  scope "/api" do
    pipe_through :api

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  scope "/api", BeamoWeb do
    pipe_through :api

    get "/health", HealthController, :show

    post "/auth/otp/start", AuthController, :start
    post "/auth/otp/verify", AuthController, :verify
  end

  scope "/api", BeamoWeb do
    pipe_through [:api, :authenticated]

    delete "/auth/session", AuthController, :logout

    get "/me", MeController, :show
    patch "/me", MeController, :update
    delete "/me", MeController, :delete
    put "/me/location", MeController, :update_location

    get "/friends", FriendController, :index
    delete "/friends/:user_id", FriendController, :unfriend
    get "/friend-requests", FriendController, :requests
    post "/friend-requests", FriendController, :create_request
    post "/friend-requests/:id/accept", FriendController, :accept_request
    delete "/friend-requests/:id", FriendController, :delete_request

    post "/contacts/match", ContactController, :match

    get "/blocks", BlockController, :index
    post "/blocks", BlockController, :create
    delete "/blocks/:user_id", BlockController, :delete

    get "/feed", FeedController, :index

    post "/beams", BeamController, :create
    get "/beams/current", BeamController, :current
    delete "/beams/current", BeamController, :end_current
    get "/beams/:id", BeamController, :show
    post "/beams/:id/seen", BeamController, :seen

    get "/communities", CommunityController, :index
    post "/communities", CommunityController, :create
    get "/communities/:id", CommunityController, :show
    patch "/communities/:id", CommunityController, :update
    post "/communities/:id/invitations", CommunityController, :invite
    post "/communities/:id/accept", CommunityController, :accept
    delete "/communities/:id/membership", CommunityController, :leave
    get "/community-invitations", CommunityController, :invitations

    get "/mutes", MuteController, :index
    post "/mutes", MuteController, :create
    delete "/mutes/:user_id", MuteController, :delete

    post "/push-tokens", PushTokenController, :create
    delete "/push-tokens/:token", PushTokenController, :delete
  end
end
