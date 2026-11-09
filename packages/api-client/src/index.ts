import createClient, { type Middleware } from "openapi-fetch";
import type { components, paths } from "./schema";

export type { components, paths };
export type Schemas = components["schemas"];

export type BeamoClientOptions = {
  baseUrl: string;
  getToken: () => string | null | Promise<string | null>;
  onUnauthorized?: () => void;
};

export function createBeamoClient({ baseUrl, getToken, onUnauthorized }: BeamoClientOptions) {
  const client = createClient<paths>({ baseUrl });

  const auth: Middleware = {
    async onRequest({ request }) {
      const token = await getToken();
      if (token) request.headers.set("Authorization", `Bearer ${token}`);
      return request;
    },
    onResponse({ response }) {
      if (response.status === 401) onUnauthorized?.();
      return response;
    },
  };

  client.use(auth);
  return client;
}

export type RealtimeEvent = "feed_changed" | "friends_changed" | "invitations_changed" | "community_changed";
