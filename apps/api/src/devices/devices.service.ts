import type { RegisterDeviceInput } from "@beamo/contracts";
import { Injectable } from "@nestjs/common";

import type { DBService } from "../db/db.service.js";

@Injectable()
export class DevicesService {
  constructor(private readonly db: DBService) {}
  async register(input: RegisterDeviceInput): Promise<void> {
    await this.db.pushToken.upsert({
      where: {
        token: input.token,
      },
      create: {
        token: input.token,
        userID: input.userId,
      },
    });

    await deviceToken.upsert({
      where: { token: input.token },
      create: {
        token: input.token,
        userId: input.userId,
        platform: input.platform,
        isActive: true,
      },
      update: {
        userId: input.userId,
        platform: input.platform,
        isActive: true,
      },
    });
  }
}
