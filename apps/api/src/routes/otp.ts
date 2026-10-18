import { randomBytes } from "node:crypto";

import { checkOTPSchema, startOTPSchema } from "@beamo/contracts/auth";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import { db } from "../db.js";
import otp from "../otp.js";
import { hashToken } from "../utils/hash-token.js";
import { SESSION_TTL } from "../utils/ttl.js";

export const OTPRoute = new Hono()
  .post("/start", zValidator("json", startOTPSchema), async c => {
    const { phone } = c.req.valid("json");

    try {
      const verification = await otp.start(phone);
      console.log(verification);
    } catch (err) {
      console.error("OPT Start failed", err);
    }

    return c.body(null, 204);
  })
  .post("/check", zValidator("json", checkOTPSchema), async c => {
    const { code, phone } = c.req.valid("json");

    try {
      const checked = await otp.check({ phone, code });
      if (checked.status !== "success")
        return c.json({ error: checked.status.replaceAll("_", " ") }, 400);

      const user = await db.user.upsert({
        where: { phone },
        create: { phone },
        update: {},
      });

      const token = randomBytes(32).toString("base64url");
      await db.session.create({
        data: {
          userID: user.id,
          tokenHash: hashToken(token),
          expiresAt: new Date(Date.now() + SESSION_TTL),
        },
      });

      return c.json({ token, user }, 200);
    } catch (e) {
      console.error("OPT check failed", e);
      return c.json({ error: "An error occured" }, 400);
    }
  });
