import { UserSchema } from "@beamo/db/validation";
import type { z } from "zod";

export const registerUserSchema = UserSchema.pick({
  phone: true,
});

export type RegisterUserInput = z.infer<typeof registerUserSchema>;

export const updateUserInputSchema = UserSchema.pick({ name: true });

export type UpdateUserInput = z.infer<typeof updateUserInputSchema>;
