import { serve } from "@hono/node-server";
import { Hono } from "hono";

import { requiredAuth } from "./auth.js";
import { pushTokenRoute } from "./routes/push-token.js";
import { userRoute } from "./routes/user.js";

const app = new Hono()
  .get("/health", c => c.json({ status: "ok" }))
  .use("/push-token/*", requiredAuth)
  .use("/user/*", requiredAuth)
  .route("/push-token", pushTokenRoute)
  .route("/user", userRoute);

export type AppType = typeof app;

const port = Number(process.env.PORT ?? 3000);
serve({ fetch: app.fetch, port, hostname: "0.0.0.0" }, () =>
  console.info(`API listening on http://localhost:${port}`)
);
