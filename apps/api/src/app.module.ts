import { Module } from '@nestjs/common';
import { HealthController } from './health/health.controller.js';
import { WorkflowsController } from './workflows/workflows.controller.js';
import { WorkflowsService } from './workflows/workflows.service.js';
import { DevicesController } from './devices/devices.controller.js';
import { DevicesService } from './devices/devices.service.js';
import { NotificationsController } from './notifications/notifications.controller.js';
import { NotificationsService } from './notifications/notifications.service.js';

@Module({
  controllers: [HealthController, WorkflowsController, DevicesController, NotificationsController],
  providers: [WorkflowsService, DevicesService, NotificationsService]
})
export class AppModule {}
