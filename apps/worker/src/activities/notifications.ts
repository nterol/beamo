import { db } from '@beamo/db';
import { sendPush } from '@beamo/notifications';

export async function sendOnboardingReminder(userId: string): Promise<void> {
  const tokens = await db.deviceToken.findMany({
    where: { userId, isActive: true },
    select: { token: true }
  });

  await Promise.all(
    tokens.map(({ token }) =>
      sendPush({
        token,
        title: 'Ton profil t\'attend',
        body: 'Complète ton profil pour augmenter tes chances de match.',
        data: { screen: 'Onboarding' }
      })
    )
  );
}
