import { z } from "zod";

export const startOTPSchema = z.object({
  phone: z.string().regex(/^\+[1-9]\d{7,14}$/),
});
