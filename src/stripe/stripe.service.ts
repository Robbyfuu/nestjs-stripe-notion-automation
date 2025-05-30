import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

@Injectable()
export class StripeService {
  private stripe: Stripe;
  private webhookSecret: string;

  constructor(@Inject(ConfigService) private configService: ConfigService) {
    this.stripe = new Stripe(this.configService.get<string>('STRIPE_SECRET_KEY')!, {
      apiVersion: '2025-05-28.basil',
    });
    this.webhookSecret = this.configService.get<string>('STRIPE_WEBHOOK_SECRET')!;
  }

  /**
   * Verifica la firma del webhook de Stripe
   */
  verifyWebhookSignature(payload: Buffer, signature: string): Stripe.Event {
    return this.stripe.webhooks.constructEvent(payload, signature, this.webhookSecret);
  }

  /**
   * Obtiene los detalles completos de un pago
   */
  async getPaymentDetails(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    return await this.stripe.paymentIntents.retrieve(paymentIntentId, {
      expand: ['latest_charge', 'latest_charge.payment_method'],
    });
  }

  /**
   * Crea un Payment Intent
   */
  async createPaymentIntent(params: Stripe.PaymentIntentCreateParams): Promise<Stripe.PaymentIntent> {
    return await this.stripe.paymentIntents.create(params);
  }

  /**
   * Obtiene información de un cliente
   */
  async getCustomer(customerId: string): Promise<Stripe.Customer> {
    return await this.stripe.customers.retrieve(customerId) as Stripe.Customer;
  }

  /**
   * Lista todos los pagos de un cliente
   */
  async listCustomerPayments(customerId: string): Promise<Stripe.ApiList<Stripe.PaymentIntent>> {
    return await this.stripe.paymentIntents.list({
      customer: customerId,
    });
  }
} 