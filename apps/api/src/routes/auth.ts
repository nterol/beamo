import { checkOTPSchema, startOTPSchema } from "@beamo/contracts/auth";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import type { WithUser } from "../middleware/auth.js";
import otp from "../otp.js";

export const authRoute = new Hono<{ Variables: WithUser }>()
  .post("/otp/start", zValidator("json", startOTPSchema), async c => {
    const { phone } = c.req.valid("json");

    try {
      const verification = await otp.start(phone);
      console.log(verification);
    } catch (err) {
      console.error("OPT Start failed", err);
    }

    return c.body(null, 204);
  })
  .post("/otp/check", zValidator("json", checkOTPSchema), async c => {
    const { code, phone } = c.req.valid("json");

    try {
      const checked = await otp.check({ phone, code });
      if (checked.status === "success") {
        return c.body(JSON.stringify({ success: true }), 200);
      }
    } catch (e) {
      console.error("OPT check failed", e);
    }
  });
