import { Injectable } from '@nestjs/common';
import { db } from '@beamo/db';
import type { UpdatePreferencesInput } from '@beamo/contracts';

@Injectable()
export class NotificationsService {
  async updatePreferences(input: UpdatePreferencesInput): Promise<void> {
    const { userId, ...values } = input;

    await db.notificationPreference.upsert({
      where: { userId },
      create: { userId, ...values },
      update: values
    });
  }
}
