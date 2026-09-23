import { z } from 'zod';
import type { Prisma } from '../prisma/client.js';

/////////////////////////////////////////
// HELPER FUNCTIONS
/////////////////////////////////////////


/////////////////////////////////////////
// ENUMS
/////////////////////////////////////////

export const TransactionIsolationLevelSchema = z.enum(['ReadUncommitted','ReadCommitted','RepeatableRead','Serializable']);

export const ActiveStatusScalarFieldEnumSchema = z.enum(['id','userID','category','createdAt','expiresAt','note']);

export const FriendshipScalarFieldEnumSchema = z.enum(['id','initiatorID','receiverID','status','createdAt','updateAt']);

export const PushTokenScalarFieldEnumSchema = z.enum(['id','userID','token','platform','isActive','createdAt','updatedAt']);

export const SessionScalarFieldEnumSchema = z.enum(['id','userID','tokenHash','createdAt','expiresAt']);

export const UserScalarFieldEnumSchema = z.enum(['id','phone','name','createdAt','updatedAt']);

export const SortOrderSchema = z.enum(['asc','desc']);

export const QueryModeSchema = z.enum(['default','insensitive']);

export const NullsOrderSchema = z.enum(['first','last']);

export const ActiveStatusCategorySchema = z.enum(['movie','drink','coffee','outdoor','sport','other']);

export type ActiveStatusCategoryType = `${z.infer<typeof ActiveStatusCategorySchema>}`

export const FriendshipStatusSchema = z.enum(['pending','accepted']);

export type FriendshipStatusType = `${z.infer<typeof FriendshipStatusSchema>}`

export const DevicePlatformSchema = z.enum(['ios','android']);

export type DevicePlatformType = `${z.infer<typeof DevicePlatformSchema>}`

/////////////////////////////////////////
// MODELS
/////////////////////////////////////////

/////////////////////////////////////////
// ACTIVE STATUS SCHEMA
/////////////////////////////////////////

export const ActiveStatusSchema = z.object({
  category: ActiveStatusCategorySchema,
  id: z.string().uuid(),
  userID: z.string(),
  createdAt: z.coerce.date(),
  expiresAt: z.coerce.date(),
  note: z.string().nullable(),
})

export type ActiveStatus = z.infer<typeof ActiveStatusSchema>

/////////////////////////////////////////
// FRIENDSHIP SCHEMA
/////////////////////////////////////////

export const FriendshipSchema = z.object({
  status: FriendshipStatusSchema,
  id: z.string().uuid(),
  initiatorID: z.string(),
  receiverID: z.string(),
  createdAt: z.coerce.date(),
  updateAt: z.coerce.date(),
})

export type Friendship = z.infer<typeof FriendshipSchema>

/////////////////////////////////////////
// PUSH TOKEN SCHEMA
/////////////////////////////////////////

export const PushTokenSchema = z.object({
  platform: DevicePlatformSchema,
  id: z.string().uuid(),
  userID: z.string(),
  token: z.string(),
  isActive: z.boolean(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
})

export type PushToken = z.infer<typeof PushTokenSchema>

/////////////////////////////////////////
// SESSION SCHEMA
/////////////////////////////////////////

export const SessionSchema = z.object({
  id: z.string().uuid(),
  userID: z.string(),
  tokenHash: z.string(),
  createdAt: z.coerce.date(),
  expiresAt: z.coerce.date(),
})

export type Session = z.infer<typeof SessionSchema>

/////////////////////////////////////////
// USER SCHEMA
/////////////////////////////////////////

export const UserSchema = z.object({
  id: z.string().uuid(),
  phone: z.string(),
  name: z.string().nullable(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
})

export type User = z.infer<typeof UserSchema>
