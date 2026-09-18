import { Body, Controller, HttpCode, Post, UsePipes } from '@nestjs/common';
import { onboardingInputSchema, type OnboardingInput } from '@beamo/contracts';
import { ZodValidationPipe } from '../common/zod-validation.pipe.js';
import { WorkflowsService } from './workflows.service.js';

@Controller('workflows')
export class WorkflowsController {
  constructor(private readonly workflowsService: WorkflowsService) {}

  @Post('onboarding')
  @HttpCode(202)
  @UsePipes(new ZodValidationPipe(onboardingInputSchema))
  start(@Body() body: OnboardingInput): Promise<{ workflowId: string }> {
    return this.workflowsService.startOnboarding(body.userId);
  }
}
