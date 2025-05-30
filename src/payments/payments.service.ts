import { Inject, Injectable } from '@nestjs/common';
import { NotionService } from '../notion/notion.service';
import { StripeService } from '../stripe/stripe.service';
import type Stripe from 'stripe';

@Injectable()
export class PaymentsService {
  constructor(
    @Inject(StripeService) private stripeService: StripeService,
    @Inject(NotionService) private notionService: NotionService,
  ) {}

  /**
   * Procesa un pago recibido de Stripe y lo registra en Notion
   */
  async processPayment(paymentIntent: Stripe.PaymentIntent) {
    try {
      // Obtenemos los detalles completos del pago
      const payment = await this.stripeService.getPaymentDetails(paymentIntent.id);

      // Extraemos la información del latest_charge expandido
      const latestCharge = payment.latest_charge as Stripe.Charge;
      const billingDetails = latestCharge?.billing_details;
      const customerEmail = billingDetails?.email || payment.receipt_email;
      const customerName = billingDetails?.name || 'Cliente sin nombre';
      const customerPhone = billingDetails?.phone;

      if (!customerEmail) {
        console.log('Pago sin email del cliente, no se puede registrar en Notion');
        return;
      }

      // Creamos o actualizamos el cliente en Notion
      const clientResponse = await this.notionService.createOrUpdateClient({
        name: customerName,
        email: customerEmail,
        phone: customerPhone,
        lastPaymentDate: new Date(payment.created * 1000),
      });

      // Obtenemos la descripción del pago desde el charge o payment intent
      const paymentDescription =
        latestCharge?.calculated_statement_descriptor ||
        latestCharge?.description ||
        payment.description ||
        'ASESORIA ONLINE';

      // Preparamos los datos del pago para Notion
      const paymentData = {
        paymentName: paymentDescription,
        amount: payment.amount,
        currency: payment.currency,
        transactionId: payment.id,
        paymentMethod: latestCharge?.payment_method_details?.type || 'card',
        status: payment.status,
        customerEmail: customerEmail,
        clientPageId: clientResponse.id,
        date: new Date(payment.created * 1000),
      };

      // Creamos el registro de pago en Notion
      const paymentResult = await this.notionService.createPaymentRecord(paymentData);

      // Actualizamos el total pagado del cliente
      await this.notionService.updateClientTotalPaid(clientResponse.id);

      console.log(`Pago registrado en Notion: ${paymentResult.id}`);
      console.log(`Cliente actualizado: ${clientResponse.id}`);

      return {
        paymentId: paymentResult.id,
        clientId: clientResponse.id,
      };
    } catch (error) {
      console.error('Error procesando pago:', error);
      throw error;
    }
  }
}
