import { NativeConnection, Worker } from '@temporalio/worker';
import * as activities from './activities/notifications.js';
import { fileURLToPath } from 'node:url';

const temporalAddress = process.env.TEMPORAL_ADDRESS ?? 'localhost:7233';
const temporalNamespace = process.env.TEMPORAL_NAMESPACE ?? 'default';

async function run(): Promise<void> {
  const workflowsPath = fileURLToPath(new URL('./workflows/onboarding.ts', import.meta.url));
  const connection = await NativeConnection.connect({ address: temporalAddress });

  const worker = await Worker.create({
    workflowsPath,
    activities,
    taskQueue: 'beamo-main',
    connection,
    namespace: temporalNamespace
  });

  await worker.run();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
