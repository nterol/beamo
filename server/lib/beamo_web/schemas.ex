defmodule BeamoWeb.Schemas do
  alias OpenApiSpex.Schema

  defdelegate uuid, to: BeamoWeb.ApiSchema
  defdelegate json(description, schema), to: BeamoWeb.ApiSchema
  defdelegate errors, to: BeamoWeb.ApiSchema

  defmodule Error do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "Error",
      %{
        error: %Schema{type: :string, description: "Code d'erreur stable, voir docs/api.md"},
        details: %Schema{
          type: :object,
          description: "Erreurs par champ",
          additionalProperties: true
        }
      },
      [:error]
    )
  end

  defmodule PublicUser do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "PublicUser",
      %{id: BeamoWeb.ApiSchema.uuid(), name: %Schema{type: :string, nullable: true}},
      [:id, :name]
    )
  end

  defmodule Me do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "Me",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        phone: %Schema{type: :string, example: "+33612345678"},
        name: %Schema{type: :string, nullable: true},
        radius_mode: %Schema{type: :string, enum: ["auto", "fixed", "unlimited"]},
        radius_km: %Schema{type: :integer, nullable: true},
        quiet_start: %Schema{type: :string, nullable: true, example: "23:00:00"},
        quiet_end: %Schema{type: :string, nullable: true, example: "08:00:00"},
        timezone: %Schema{type: :string, example: "Europe/Paris"},
        located_at: %Schema{type: :string, format: :"date-time", nullable: true}
      },
      [
        :id,
        :phone,
        :name,
        :radius_mode,
        :radius_km,
        :quiet_start,
        :quiet_end,
        :timezone,
        :located_at
      ]
    )
  end

  defmodule OtpStartRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "OtpStartRequest",
      %{phone: %Schema{type: :string, description: "E.164", example: "+33612345678"}},
      [:phone]
    )
  end

  defmodule OtpVerifyRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "OtpVerifyRequest",
      %{phone: %Schema{type: :string}, code: %Schema{type: :string}},
      [:phone, :code]
    )
  end

  defmodule AuthResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "AuthResponse",
      %{
        token: %Schema{
          type: :string,
          description: "Bearer token, à stocker dans expo-secure-store"
        },
        user: Me,
        is_new: %Schema{
          type: :boolean,
          description: "Vrai tant que le prénom n'est pas renseigné"
        }
      },
      [:token, :user, :is_new]
    )
  end

  defmodule MeUpdateRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "MeUpdateRequest",
      %{
        name: %Schema{type: :string, minLength: 1, maxLength: 40},
        radius_mode: %Schema{type: :string, enum: ["auto", "fixed", "unlimited"]},
        radius_km: %Schema{type: :integer, minimum: 1, maximum: 500, nullable: true},
        quiet_start: %Schema{type: :string, nullable: true, example: "23:00:00"},
        quiet_end: %Schema{type: :string, nullable: true, example: "08:00:00"},
        timezone: %Schema{type: :string, example: "Europe/Paris"}
      },
      []
    )
  end

  defmodule LocationRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "LocationRequest",
      %{lat: %Schema{type: :number}, lng: %Schema{type: :number}},
      [:lat, :lng]
    )
  end

  defmodule UserIdRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object("UserIdRequest", %{user_id: BeamoWeb.ApiSchema.uuid()}, [:user_id])
  end

  defmodule FriendsResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "FriendsResponse",
      %{friends: %Schema{type: :array, items: PublicUser}},
      [:friends]
    )
  end

  defmodule FriendRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "FriendRequest",
      %{id: BeamoWeb.ApiSchema.uuid(), user: PublicUser},
      [:id, :user]
    )
  end

  defmodule FriendRequestsResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "FriendRequestsResponse",
      %{
        incoming: %Schema{type: :array, items: FriendRequest},
        outgoing: %Schema{type: :array, items: FriendRequest}
      },
      [:incoming, :outgoing]
    )
  end

  defmodule Friendship do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "Friendship",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        status: %Schema{type: :string, enum: ["pending", "accepted"]}
      },
      [:id, :status]
    )
  end

  defmodule ContactMatchRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "ContactMatchRequest",
      %{
        hashes: %Schema{
          type: :array,
          maxItems: 2000,
          items: %Schema{type: :string, description: "sha256 hex d'un numéro E.164"}
        }
      },
      [:hashes]
    )
  end

  defmodule ContactMatch do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "ContactMatch",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        name: %Schema{type: :string, nullable: true},
        relation: %Schema{type: :string, enum: ["friend", "outgoing", "incoming", "none"]}
      },
      [:id, :name, :relation]
    )
  end

  defmodule ContactMatchResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "ContactMatchResponse",
      %{matches: %Schema{type: :array, items: ContactMatch}},
      [:matches]
    )
  end

  defmodule BlocksResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "BlocksResponse",
      %{blocked: %Schema{type: :array, items: PublicUser}},
      [:blocked]
    )
  end

  defmodule MutesResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "MutesResponse",
      %{muted: %Schema{type: :array, items: PublicUser}},
      [:muted]
    )
  end

  defmodule PushTokenRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "PushTokenRequest",
      %{
        token: %Schema{type: :string, example: "ExponentPushToken[xxxx]"},
        platform: %Schema{type: :string, enum: ["ios", "android"]}
      },
      [:token, :platform]
    )
  end

  defmodule Beam do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "Beam",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        category: %Schema{
          type: :string,
          enum: ["movie", "drink", "coffee", "outdoor", "sport", "other"]
        },
        note: %Schema{type: :string, nullable: true},
        parent_id: %Schema{type: :string, format: :uuid, nullable: true},
        expires_at: %Schema{type: :string, format: :"date-time"},
        inserted_at: %Schema{type: :string, format: :"date-time"}
      },
      [:id, :category, :note, :parent_id, :expires_at, :inserted_at]
    )
  end

  defmodule BeamCreateRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "BeamCreateRequest",
      %{
        category: %Schema{
          type: :string,
          enum: ["movie", "drink", "coffee", "outdoor", "sport", "other"]
        },
        note: %Schema{type: :string, maxLength: 140},
        lat: %Schema{type: :number},
        lng: %Schema{type: :number},
        parent_id: %Schema{
          type: :string,
          format: :uuid,
          description: "Beam reçu auquel on répond"
        }
      },
      [:category]
    )
  end

  defmodule BeamResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object("BeamResponse", %{beam: Beam}, [:beam])
  end

  defmodule CurrentBeamResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CurrentBeamResponse",
      %{
        beam: BeamoWeb.ApiSchema.nullable(Beam),
        reached: %Schema{type: :integer, description: "Amis ayant reçu le beam"},
        seen: %Schema{type: :integer},
        replies: %Schema{type: :array, items: PublicUser}
      },
      [:beam]
    )
  end

  defmodule ReceivedBeam do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "ReceivedBeam",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        category: %Schema{
          type: :string,
          enum: ["movie", "drink", "coffee", "outdoor", "sport", "other"]
        },
        note: %Schema{type: :string, nullable: true},
        parent_id: %Schema{type: :string, format: :uuid, nullable: true},
        expires_at: %Schema{type: :string, format: :"date-time"},
        inserted_at: %Schema{type: :string, format: :"date-time"},
        user: PublicUser,
        active: %Schema{type: :boolean},
        distance_km: %Schema{type: :integer, nullable: true}
      },
      [:id, :category, :note, :parent_id, :expires_at, :inserted_at, :user, :active, :distance_km]
    )
  end

  defmodule ReceivedBeamResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object("ReceivedBeamResponse", %{beam: ReceivedBeam}, [:beam])
  end

  defmodule FeedEntry do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "FeedEntry",
      %{
        user: PublicUser,
        beam: BeamoWeb.ApiSchema.nullable(Beam),
        distance_km: %Schema{type: :integer, nullable: true}
      },
      [:user, :beam, :distance_km]
    )
  end

  defmodule FeedResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "FeedResponse",
      %{
        active: %Schema{
          type: :boolean,
          description: "Faux : fil flouté, seul active_count est fourni"
        },
        active_count: %Schema{type: :integer},
        beam: Beam,
        friends: %Schema{type: :array, items: FeedEntry}
      },
      [:active]
    )
  end

  defmodule CommunitySummary do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunitySummary",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        name: %Schema{type: :string},
        member_count: %Schema{type: :integer}
      },
      [:id, :name, :member_count]
    )
  end

  defmodule CommunitiesResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunitiesResponse",
      %{communities: %Schema{type: :array, items: CommunitySummary}},
      [:communities]
    )
  end

  defmodule Community do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "Community",
      %{id: BeamoWeb.ApiSchema.uuid(), name: %Schema{type: :string}},
      [:id, :name]
    )
  end

  defmodule CommunityCreateRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunityCreateRequest",
      %{
        name: %Schema{type: :string, minLength: 1, maxLength: 40},
        user_ids: %Schema{
          type: :array,
          minItems: 1,
          items: BeamoWeb.ApiSchema.uuid(),
          description: "Amis à inviter"
        }
      },
      [:name, :user_ids]
    )
  end

  defmodule CommunityRenameRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunityRenameRequest",
      %{name: %Schema{type: :string, minLength: 1, maxLength: 40}},
      [:name]
    )
  end

  defmodule CommunityInviteRequest do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunityInviteRequest",
      %{
        user_ids: %Schema{
          type: :array,
          minItems: 1,
          items: BeamoWeb.ApiSchema.uuid(),
          description: "Mes amis"
        }
      },
      [:user_ids]
    )
  end

  defmodule CommunityMember do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunityMember",
      %{
        status: %Schema{type: :string, enum: ["member", "invited"]},
        user: BeamoWeb.ApiSchema.nullable(PublicUser),
        invited_by: BeamoWeb.ApiSchema.nullable(PublicUser),
        beam: BeamoWeb.ApiSchema.nullable(Beam),
        distance_km: %Schema{type: :integer, nullable: true}
      },
      [:status, :user]
    )
  end

  defmodule CommunityResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "CommunityResponse",
      %{
        id: BeamoWeb.ApiSchema.uuid(),
        name: %Schema{type: :string},
        active: %Schema{type: :boolean},
        active_count: %Schema{type: :integer},
        members: %Schema{type: :array, items: CommunityMember}
      },
      [:id, :name, :active, :active_count, :members]
    )
  end

  defmodule InviteResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object("InviteResponse", %{invited: %Schema{type: :integer}}, [:invited])
  end

  defmodule Invitation do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "Invitation",
      %{community: Community, invited_by: BeamoWeb.ApiSchema.nullable(PublicUser)},
      [:community, :invited_by]
    )
  end

  defmodule InvitationsResponse do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object(
      "InvitationsResponse",
      %{invitations: %Schema{type: :array, items: Invitation}},
      [:invitations]
    )
  end

  defmodule Health do
    require BeamoWeb.ApiSchema

    BeamoWeb.ApiSchema.object("Health", %{status: %Schema{type: :string}}, [:status])
  end
end
