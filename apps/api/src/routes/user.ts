import { updateUserInputSchema } from "@beamo/contracts/user";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import { db } from "../db.js";
import type { AuthMiddleWareCTX } from "../middleware/auth.js";

export const userRoute = new Hono<{ Variables: AuthMiddleWareCTX }>()
  .get("/me", async c => {
    const user = c.get("user");
    return c.json(user, 200);
  })
  .patch("/me", zValidator("json", updateUserInputSchema), async c => {
    const user = c.get("user");
    const update = c.req.valid("json");
    try {
      const updatedUser = await db.user.update({
        where: { id: user.id },
        data: update,
      });
      return c.json({ user: updatedUser }, 200);
    } catch (_error) {
      return c.json({ error: "Could not update user" }, 500);
    }
  });
