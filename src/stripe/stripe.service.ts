import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import type { Stripe as StripeTypes } from 'stripe';

@Injectable()
export class StripeService {
  private stripe: Stripe;
  private webhookSecret: string;

  constructor(private configService: ConfigService) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    this.webhookSecret = this.configService.get<string>('STRIPE_WEBHOOK_SECRET');

    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY no está configurada en las variables de entorno');
    }

    if (!this.webhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET no está configurada en las variables de entorno');
    }

    this.stripe = new Stripe(secretKey, {
      apiVersion: '2025-05-28.basil',
    });
  }

  /**
   * Verifica la firma del webhook de Stripe
   */
  verifyWebhookSignature(payload: Buffer, signature: string): StripeTypes.Event {
    return this.stripe.webhooks.constructEvent(payload, signature, this.webhookSecret);
  }

  /**
   * Obtiene los detalles completos de un PaymentIntent
   */
  async getPaymentIntent(paymentIntentId: string): Promise<StripeTypes.PaymentIntent> {
    return await this.stripe.paymentIntents.retrieve(paymentIntentId, {
      expand: ['customer'],
    });
  }

  /**
   * Crea un PaymentIntent
   */
  async createPaymentIntent(amount: number, currency = 'usd', metadata?: Record<string, string>): Promise<StripeTypes.PaymentIntent> {
    return await this.stripe.paymentIntents.create({
      amount,
      currency,
      metadata,
    });
  }

  /**
   * Obtiene información del cliente
   */
  async getCustomer(customerId: string): Promise<StripeTypes.Customer> {
    const customer = await this.stripe.customers.retrieve(customerId);
    if (customer.deleted) {
      throw new Error('El cliente ha sido eliminado');
    }
    return customer as StripeTypes.Customer;
  }

  /**
   * Obtiene los detalles completos de un pago
   */
  async getPaymentDetails(paymentIntentId: string): Promise<StripeTypes.PaymentIntent> {
    return await this.stripe.paymentIntents.retrieve(paymentIntentId, {
      expand: ['latest_charge'],
    });
  }

  /**
   * Lista todos los pagos de un cliente
   */
  async listCustomerPayments(customerId: string): Promise<StripeTypes.ApiList<StripeTypes.PaymentIntent>> {
    return await this.stripe.paymentIntents.list({
      customer: customerId,
    });
  }
}
