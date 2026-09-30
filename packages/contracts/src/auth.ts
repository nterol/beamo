import { z } from "zod";

const PhoneSchema = z.string().regex(/^\+[1-9]\d{7,14}$/);

export const startOTPSchema = z.object({
  phone: PhoneSchema,
});

export const checkOTPSchema = z.object({
  phone: PhoneSchema,
  code: z.string(),
});
