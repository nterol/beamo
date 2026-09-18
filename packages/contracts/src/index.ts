import { z } from 'zod';

export const onboardingInputSchema = z.object({
  userId: z.string().min(1)
});

export type OnboardingInput = z.infer<typeof onboardingInputSchema>;

export async function onboardingWorkflow(userId: string): Promise<void> {
  void userId;
}

export const devicePlatformSchema = z.enum(['ios', 'android']);

export type DevicePlatform = z.infer<typeof devicePlatformSchema>;

export const registerDeviceSchema = z.object({
  userId: z.string().min(1),
  token: z.string().min(10),
  platform: devicePlatformSchema
});

export type RegisterDeviceInput = z.infer<typeof registerDeviceSchema>;

export const updatePreferencesSchema = z.object({
  userId: z.string().min(1),
  likesEnabled: z.boolean().optional(),
  matchesEnabled: z.boolean().optional(),
  messagesEnabled: z.boolean().optional(),
  remindersEnabled: z.boolean().optional(),
  maxNotificationsDay: z.number().int().min(1).max(100).optional(),
  quietHoursStart: z.number().int().min(0).max(23).optional(),
  quietHoursEnd: z.number().int().min(0).max(23).optional(),
  timezone: z.string().optional()
});

export type UpdatePreferencesInput = z.infer<typeof updatePreferencesSchema>;
