import { Injectable } from '@nestjs/common';
import { Connection, WorkflowClient } from '@temporalio/client';
import { onboardingWorkflow } from '@beamo/contracts';

const temporalAddress = process.env.TEMPORAL_ADDRESS ?? 'localhost:7233';
const temporalNamespace = process.env.TEMPORAL_NAMESPACE ?? 'default';

@Injectable()
export class WorkflowsService {
  async startOnboarding(userId: string): Promise<{ workflowId: string }> {
    const connection = await Connection.connect({ address: temporalAddress });
    const client = new WorkflowClient({ connection, namespace: temporalNamespace });

    const workflowId = `user-${userId}-onboarding`;

    await client.start(onboardingWorkflow, {
      taskQueue: 'beamo-main',
      workflowId,
      args: [userId]
    });

    return { workflowId };
  }
}
