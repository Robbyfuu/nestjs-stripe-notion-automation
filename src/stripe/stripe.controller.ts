import { Body, Controller, Headers, Inject, Post, type RawBodyRequest, Req } from '@nestjs/common';
import type { Request } from 'express';
import type Stripe from 'stripe';
import { PaymentsService } from '../payments/payments.service';
import { StripeService } from './stripe.service';

@Controller('webhook')
export class StripeController {
  constructor(
    @Inject(StripeService) private stripeService: StripeService,
    @Inject(PaymentsService) private paymentsService: PaymentsService,
  ) {}

  @Post('stripe')
  async handleStripeWebhook(@Req() request: RawBodyRequest<Request>, @Headers('stripe-signature') signature: string) {
    try {
      if (!request.rawBody || !signature) {
        throw new Error('Invalid request: Missing payload or signature');
      }

      const payload = request.rawBody;
      let event: Stripe.Event;

      try {
        event = this.stripeService.verifyWebhookSignature(payload, signature);
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        const errorType =
          error && typeof error === 'object' && 'type' in error ? (error as { type: string }).type : 'SignatureVerificationError';
        console.error(`Error verifying webhook signature (${errorType}):`, errorMessage);
        throw new Error('Invalid signature');
      }

      // Procesamos sólo eventos de pago completados
      if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await this.paymentsService.processPayment(paymentIntent);
        return { received: true };
      }

      return { received: true };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const errorType = error && typeof error === 'object' && 'type' in error ? (error as { type: string }).type : 'UnknownError';
      console.error(`Error processing webhook (${errorType}):`, errorMessage);
      throw new Error(`Error processing webhook: ${errorMessage}`);
    }
  }
}
