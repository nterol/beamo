import { createHash } from "node:crypto";

import type { User } from "@beamo/db/validation";
import { createMiddleware } from "hono/factory";

import { db } from "./db.js";

const DAY = 24 * 60 * 60 * 1000;
export const SESSION_TTL = 90 * DAY;

export const hashToken = (token: string) =>
  createHash("sha256").update(token).digest("hex");

export type WithUser = { user: User };

export const requiredAuth = createMiddleware<{ Variables: WithUser }>(
  async (c, next) => {
    const token = c.req.header("Authorization")?.replace(/^Bearer/, "");
    if (!token) return c.json({ error: "unauthorized" }, 401);

    const session = await db.session.findUnique({
      where: { tokenHash: hashToken(token) },
      include: { user: true },
    });
    if (!session || session.expiresAt < new Date())
      return c.json({ error: "unauthorized" }, 401);

    if (session.expiresAt.getTime() - Date.now() < 60 * DAY) {
      await db.session.update({
        where: { id: session.id },
        data: { expiresAt: new Date(Date.now() + SESSION_TTL) },
      });

      c.set("user", session.user);
      await next();
    }
  }
);
