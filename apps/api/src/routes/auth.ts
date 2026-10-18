import { Hono } from "hono";

import { db } from "../db.js";
import type { AuthMiddleWareCTX } from "../middleware/auth.js";
import { OTPRoute } from "./otp.js";

export const authRoute = new Hono<{ Variables: AuthMiddleWareCTX }>()
  .delete("/session", async c => {
    const tokenHash = c.get("sessionToken");
    try {
      await db.session.delete({ where: { tokenHash } });
      return c.json({ success: true }, 200);
    } catch (_e) {
      return c.json({ success: false }, 500);
    }
  })
  .route("/otp/", OTPRoute);
