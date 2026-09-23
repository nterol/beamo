import { DevicePlatformSchema, PushTokenSchema } from "@beamo/db/validation";
import { z } from "zod";

export const onboardingInputSchema = z.object({
  userID: z.string().min(1),
});

export type OnboardingInput = z.infer<typeof onboardingInputSchema>;

export async function onboardingWorkflow(userID: string): Promise<void> {
  void userID;
}

export const devicePlatformSchema = DevicePlatformSchema;

export type DevicePlatform = z.infer<typeof devicePlatformSchema>;

export const registerPushTokenSchema = PushTokenSchema.pick({
  token: true,
  platform: true,
}).extend({ token: PushTokenSchema.shape.token.min(10) });

export const deletePushTokenSchema = PushTokenSchema.pick({
  token: true,
});

export type RegisterPushTokenInput = z.infer<typeof registerPushTokenSchema>;

export type DeletePushTokenInput = z.infer<typeof deletePushTokenSchema>;

export const updatePreferencesSchema = z.object({
  userId: z.string().min(1),
  likesEnabled: z.boolean().optional(),
  matchesEnabled: z.boolean().optional(),
  messagesEnabled: z.boolean().optional(),
  remindersEnabled: z.boolean().optional(),
  maxNotificationsDay: z.number().int().min(1).max(100).optional(),
  quietHoursStart: z.number().int().min(0).max(23).optional(),
  quietHoursEnd: z.number().int().min(0).max(23).optional(),
  timezone: z.string().optional(),
});

export type UpdatePreferencesInput = z.infer<typeof updatePreferencesSchema>;
