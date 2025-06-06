import { Module, forwardRef } from '@nestjs/common';
import { NotionModule } from '../notion/notion.module';
import { StripeModule } from '../stripe/stripe.module';
import { PaymentsService } from './payments.service';

@Module({
  imports: [forwardRef(() => StripeModule), NotionModule],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
