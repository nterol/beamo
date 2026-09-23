import { onboardingInputSchema, onboardingWorkflow } from "@beamo/contracts";
import { zValidator } from "@hono/zod-validator";
import { Connection, WorkflowClient } from "@temporalio/client";
import { Hono } from "hono";

const temporalAddress = process.env.TEMPORAL_ADDRESS ?? "localhost:7233";
const temporalNamespace = process.env.TEMPORAL_NAMESPACE ?? "default";

export const worflowsRoute = new Hono().post(
  "/onboarding",
  zValidator("json", onboardingInputSchema),
  async c => {
    const { userID } = c.req.valid("json");
    const connection = await Connection.connect({ address: temporalAddress });
    const client = new WorkflowClient({
      connection,
      namespace: temporalNamespace,
    });

    const workflowId = `user-${userID}-onboarding`;

    await client.start(onboardingWorkflow, {
      taskQueue: "beamo-main",
      workflowId,
      args: [userID],
    });

    return c.json({ workflowId }, 200);
  }
);
