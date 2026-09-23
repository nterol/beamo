import { updateUserInputSchema } from "@beamo/contracts/user";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import { db } from "../db.js";
import type { WithUser } from "../middleware/auth.js";

export const userRoute = new Hono<{ Variables: WithUser }>()
  .get("/me", async c => {
    const user = c.get("user");
    return c.json(user, 200);
  })
  .patch("/me", zValidator("json", updateUserInputSchema), async c => {
    const user = c.get("user");
    const update = c.req.valid("json");
    await db.user.update({ where: { id: user.id }, data: update });
  });
