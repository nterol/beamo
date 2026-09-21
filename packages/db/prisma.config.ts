import { config } from "dotenv";
import { defineConfig, env } from "prisma/config";

config({ path: "../../.env", quiet: true });

export default defineConfig({
  datasource: {
    url: env("DATABASE_URL"),
  },
  schema: "prisma",
  migrations: { path: "prisma/migrations" },
});
