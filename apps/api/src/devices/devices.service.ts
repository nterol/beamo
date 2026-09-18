import { Injectable } from '@nestjs/common';
import { db } from '@beamo/db';
import type { RegisterDeviceInput } from '@beamo/contracts';

@Injectable()
export class DevicesService {
  async register(input: RegisterDeviceInput): Promise<void> {
    await db.deviceToken.upsert({
      where: { token: input.token },
      create: { token: input.token, userId: input.userId, platform: input.platform, isActive: true },
      update: { userId: input.userId, platform: input.platform, isActive: true }
    });
  }
}
