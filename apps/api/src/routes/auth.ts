import { randomBytes } from "node:crypto";

import { checkOTPSchema, startOTPSchema } from "@beamo/contracts/auth";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import { db } from "../db.js";
import { SESSION_TTL, type WithUser } from "../middleware/auth.js";
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
      if (
        checked.status === "expired_or_not_found" ||
        checked.status === "transaction_mismatch"
      )
        return c.json({ error: "invalid_code" }, 400);
      if (checked.status === "success") {
        const user = await db.user.upsert({
          where: { phone },
          create: { phone },
          update: {},
        });

        const tokenHash = randomBytes(32).toString("base64url");
        await db.session.create({
          data: {
            userID: user.id,
            tokenHash,
            expiresAt: new Date(Date.now() + SESSION_TTL),
          },
        });

        return c.json({ token: tokenHash, user });
      }
    } catch (e) {
      console.error("OPT check failed", e);
    }
  });
