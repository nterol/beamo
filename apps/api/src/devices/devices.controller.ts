import {
  type RegisterDeviceInput,
  registerDeviceSchema,
} from "@beamo/contracts";
import { Body, Controller, HttpCode, Post, UsePipes } from "@nestjs/common";

import { ZodValidationPipe } from "../common/zod-validation.pipe.js";
import type { DevicesService } from "./devices.service.js";

@Controller("devices")
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Post("register")
  @HttpCode(201)
  @UsePipes(new ZodValidationPipe(registerDeviceSchema))
  async register(
    @Body() body: RegisterDeviceInput
  ): Promise<{ success: true }> {
    await this.devicesService.register(body);
    return { success: true };
  }
}
