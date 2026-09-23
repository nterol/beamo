import { startOTPSchema } from "@beamo/contracts/auth";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import type { WithUser } from "../middleware/auth.js";
import otp from "../opt.js";

export const authRoute = new Hono<{ Variables: WithUser }>().post(
  "/otp/start",
  zValidator("json", startOTPSchema),
  async c => {
    const { phone } = c.req.valid("json");

    try {
      await otp.start(phone);
    } catch (err) {
      console.error("OPT Start faild", err);
    }

    return c.body(null, 204);
  }
);
