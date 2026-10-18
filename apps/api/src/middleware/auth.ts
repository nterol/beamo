import type { Session, User } from "@beamo/db/validation";
import { createMiddleware } from "hono/factory";

import { db } from "../db.js";
import { hashToken } from "../utils/hash-token.js";
import { DAY, SESSION_TTL } from "../utils/ttl.js";

export type AuthMiddleWareCTX = { user: User; sessionToken: string };

export const requiredAuth = createMiddleware<{
  Variables: AuthMiddleWareCTX;
}>(async (c, next) => {
  const token = c.req.header("Authorization")?.replace(/^Bearer\s+/, "");
  if (!token) return c.json({ error: "unauthorized" }, 401);
  let session: Session & { user: User };
  session = await db.session.findUnique({
    where: { tokenHash: hashToken(token) },
    include: { user: true },
  });
  if (!session || session.expiresAt < new Date())
    return c.json({ error: "unauthorized" }, 401);

  if (session.expiresAt.getTime() - Date.now() < 60 * DAY) {
    session = await db.session.update({
      where: { id: session.id },
      data: { expiresAt: new Date(Date.now() + SESSION_TTL) },
    });
  }
  c.set("user", session.user);
  c.set("sessionToken", session.tokenHash);
  await next();
});
