import { Module } from "@nestjs/common";

import { DBModule } from "./db/db.module.js";
import { DevicesController } from "./devices/devices.controller.js";
import { DevicesService } from "./devices/devices.service.js";
import { HealthController } from "./health/health.controller.js";
import { NotificationsController } from "./notifications/notifications.controller.js";
import { NotificationsService } from "./notifications/notifications.service.js";
import { WorkflowsController } from "./workflows/workflows.controller.js";
import { WorkflowsService } from "./workflows/workflows.service.js";

@Module({
  imports: [DBModule],
  controllers: [
    HealthController,
    WorkflowsController,
    DevicesController,
    NotificationsController,
  ],
  providers: [WorkflowsService, DevicesService, NotificationsService],
})
export class AppModule {}
