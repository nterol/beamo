defmodule BeamoWeb.Router do
  use BeamoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug BeamoWeb.Plugs.Auth
  end

  scope "/api", BeamoWeb do
    pipe_through :api

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

    post "/push-tokens", PushTokenController, :create
    delete "/push-tokens/:token", PushTokenController, :delete
  end
end
