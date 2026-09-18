import { proxyActivities, sleep } from '@temporalio/workflow';

type Activities = {
  sendOnboardingReminder: (userId: string) => Promise<void>;
};

const { sendOnboardingReminder } = proxyActivities<Activities>({
  startToCloseTimeout: '1 minute',
  retry: {
    initialInterval: '2 seconds',
    maximumAttempts: 5
  }
});

export async function onboardingWorkflow(userId: string): Promise<void> {
  await sleep('48 hours');
  await sendOnboardingReminder(userId);
}
