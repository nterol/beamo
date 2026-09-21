import { PrismaClient } from "@beamo/db";
import {
  Injectable,
  type OnModuleDestroy,
  type OnModuleInit,
} from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";

@Injectable()
export class DBService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    super({
      adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
    });
  }
  onModuleInit() {
    return this.$connect();
  }
  onModuleDestroy() {
    return this.$disconnect();
  }
}
