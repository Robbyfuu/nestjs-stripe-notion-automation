import { Inject, Injectable } from '@nestjs/common';
import type Stripe from 'stripe';
import { NotionService } from '../notion/notion.service';
import { StripeService } from '../stripe/stripe.service';

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
      
      let customerEmail = billingDetails?.email || payment.receipt_email;
      let customerName = billingDetails?.name || 'Cliente sin nombre';
      let customerPhone = billingDetails?.phone;
      
      // Si no hay email en billing_details pero hay customer ID, obtener del customer
      if (!customerEmail && payment.customer) {
        try {
          const customer = await this.stripeService.getCustomer(payment.customer as string);
          customerEmail = customer.email;
          customerName = customer.name || customerName;
          customerPhone = customer.phone || customerPhone;
        } catch (error) {
          console.log('Error obteniendo datos del customer:', error.message);
        }
      }

      if (!customerEmail) {
        console.log('Pago sin email del cliente, no se puede registrar en Notion');
        return;
      }

      console.log(`✅ Procesando pago: ${customerEmail} - $${(payment.amount / 100).toFixed(2)} ${payment.currency.toUpperCase()}`);

      // Creamos o actualizamos el cliente en Notion
      const clientResponse = await this.notionService.createOrUpdateClient({
        name: customerName,
        email: customerEmail,
        phone: customerPhone,
        lastPaymentDate: new Date(payment.created * 1000),
      });

      // Obtenemos la descripción del pago desde el charge o payment intent
      const paymentDescription =
        latestCharge?.calculated_statement_descriptor || latestCharge?.description || payment.description || 'ASESORIA ONLINE';

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

      // Creamos el evento de calendario para el pago recibido
      try {
        const paymentMethodDetails = latestCharge?.payment_method_details 
          ? `${latestCharge.payment_method_details.type}${latestCharge.payment_method_details.card ? ` •••• ${latestCharge.payment_method_details.card.last4}` : ''}`
          : undefined;

        await this.notionService.createPaymentCalendarEvent({
          clientName: customerName,
          clientEmail: customerEmail,
          amount: payment.amount,
          currency: payment.currency,
          transactionId: payment.id,
          paymentDate: new Date(payment.created * 1000),
          paymentMethodDetails,
        });

        console.log(`✅ Evento de calendario creado para el pago de ${customerName}`);
      } catch (calendarError) {
        console.error('Error creando evento de calendario:', calendarError);
        // No lanzamos el error para que no falle todo el proceso si solo falla el calendario
      }

      console.log(`✅ Pago registrado en Notion: ${paymentResult.id}`);

      return {
        paymentId: paymentResult.id,
        clientId: clientResponse.id,
      };
    } catch (error) {
      console.error('Error procesando pago:', error);
      throw error;
    }
  }

  /**
   * Procesa un pago de test sin hacer llamadas a la API de Stripe
   */
  async processTestPayment(paymentIntent: Stripe.PaymentIntent) {
    try {
      console.log('🧪 Procesando pago de test:', paymentIntent.id);

      // Para testing, usamos los datos directamente del payload sin llamadas a Stripe
      let customerEmail: string | null = null;
      let customerName = 'Cliente sin nombre';
      let customerPhone: string | null = null;

      // Extraer email del customer si está disponible
      if (paymentIntent.customer && typeof paymentIntent.customer === 'object') {
        const customer = paymentIntent.customer as any;
        customerEmail = customer.email;
        customerName = customer.name || customerName;
        customerPhone = customer.phone;
      }

      // Fallback a metadata si no hay customer
      if (!customerEmail && paymentIntent.metadata) {
        customerEmail = paymentIntent.metadata.customer_email;
        customerName = paymentIntent.metadata.customer_name || customerName;
      }

      if (!customerEmail) {
        console.log('🧪 Pago de test sin email del cliente, no se puede registrar en Notion');
        return;
      }

      console.log(`🧪 Procesando pago de test: ${customerEmail} - $${(paymentIntent.amount / 100).toFixed(2)} ${paymentIntent.currency.toUpperCase()}`);

      // Creamos o actualizamos el cliente en Notion
      const clientResponse = await this.notionService.createOrUpdateClient({
        name: customerName,
        email: customerEmail,
        phone: customerPhone,
        lastPaymentDate: new Date(), // Para test usamos fecha actual
      });

      // Preparamos los datos del pago para Notion
      const paymentData = {
        paymentName: 'PAGO DE TEST - ASESORIA ONLINE',
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        transactionId: paymentIntent.id,
        paymentMethod: 'card',
        status: paymentIntent.status,
        customerEmail: customerEmail,
        clientPageId: clientResponse.id,
        date: new Date(), // Para test usamos fecha actual
      };

      // Creamos el registro de pago en Notion
      const paymentResult = await this.notionService.createPaymentRecord(paymentData);

      // Actualizamos el total pagado del cliente
      await this.notionService.updateClientTotalPaid(clientResponse.id);

      // Creamos el evento de calendario para el pago recibido
      try {
        await this.notionService.createPaymentCalendarEvent({
          clientName: customerName,
          clientEmail: customerEmail,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          transactionId: paymentIntent.id,
          paymentDate: new Date(),
          paymentMethodDetails: 'card •••• 4242 (TEST)',
        });

        console.log(`🧪 Evento de calendario de test creado para ${customerName}`);
      } catch (calendarError) {
        console.error('Error creando evento de calendario de test:', calendarError);
        // No lanzamos el error para que no falle todo el proceso si solo falla el calendario
      }

      console.log(`🧪 Pago de test registrado en Notion: ${paymentResult.id}`);

      return {
        paymentId: paymentResult.id,
        clientId: clientResponse.id,
      };
    } catch (error) {
      console.error('Error procesando pago de test:', error);
      throw error;
    }
  }
}
