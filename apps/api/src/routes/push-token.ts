import {
  deletePushTokenSchema,
  registerPushTokenSchema,
} from "@beamo/contracts";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import { db } from "../db.js";
import type { WithUser } from "../middleware/auth.js";

export const pushTokenRoute = new Hono<{
  Variables: WithUser;
}>()
  .post("/", zValidator("json", registerPushTokenSchema), async ctx => {
    const { token, platform } = ctx.req.valid("json");
    const { id: userID } = ctx.get("user");
    await db.pushToken.upsert({
      where: { token },
      create: { token, userID, platform, isActive: true },
      update: { userID, platform, isActive: true },
    });

    return ctx.json({ success: true }, 201);
  })
  .delete("/", zValidator("json", deletePushTokenSchema), async c => {
    await db.pushToken.delete({ where: { token: c.req.valid("json").token } });
    return c.body(null, 204);
  });
