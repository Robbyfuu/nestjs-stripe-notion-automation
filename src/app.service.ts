import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'NestJS + Stripe + Notion Integration API is running!';
  }
}
