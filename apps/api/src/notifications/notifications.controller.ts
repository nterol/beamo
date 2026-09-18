import { Body, Controller, Put, UsePipes } from '@nestjs/common';
import { updatePreferencesSchema, type UpdatePreferencesInput } from '@beamo/contracts';
import { ZodValidationPipe } from '../common/zod-validation.pipe.js';
import { NotificationsService } from './notifications.service.js';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Put('preferences')
  @UsePipes(new ZodValidationPipe(updatePreferencesSchema))
  async updatePreferences(@Body() body: UpdatePreferencesInput): Promise<{ success: true }> {
    await this.notificationsService.updatePreferences(body);
    return { success: true };
  }
}
