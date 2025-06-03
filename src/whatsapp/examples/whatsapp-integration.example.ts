import { Injectable } from '@nestjs/common';
import { WhatsappService } from '../whatsapp.service';

/**
 * Ejemplo de integración de WhatsApp con Stripe y Notion
 * 
 * Este archivo muestra cómo usar el servicio de WhatsApp
 * en diferentes escenarios de tu aplicación
 */

@Injectable()
export class WhatsappIntegrationExample {
  constructor(private readonly whatsappService: WhatsappService) {}

  /**
   * Ejemplo 1: Notificar pago exitoso desde webhook de Stripe
   */
  async onStripePaymentSuccess(stripeEvent: any) {
    const paymentIntent = stripeEvent.data.object;
    
    // Datos del cliente (normalmente vendrían de tu base de datos o Notion)
    const customerData = {
      phone: '+5215551234567', // Número del cliente
      name: 'Juan Pérez',
      email: paymentIntent.receipt_email,
    };

    // Enviar notificación de pago exitoso
    const result = await this.whatsappService.sendPaymentConfirmation(
      customerData.phone,
      customerData.name,
      paymentIntent.amount / 100, // Stripe usa centavos
      paymentIntent.id,
    );

    if (result.success) {
      console.log('✅ Notificación WhatsApp enviada exitosamente');
    } else {
      console.error('❌ Error enviando notificación WhatsApp:', result.error);
    }
  }

  /**
   * Ejemplo 2: Mensaje de bienvenida para nuevos clientes
   */
  async welcomeNewCustomer(customerPhone: string, customerName: string) {
    return await this.whatsappService.sendWelcomeMessage(
      customerPhone,
      customerName,
    );
  }

  /**
   * Ejemplo 3: Notificación de envío cuando se actualiza el estado en Notion
   */
  async onOrderShipped(orderData: any) {
    return await this.whatsappService.sendShipmentNotification(
      orderData.customerPhone,
      orderData.customerName,
      orderData.orderId,
      orderData.trackingNumber,
    );
  }

  /**
   * Ejemplo 4: Campaña promocional a lista de clientes
   */
  async sendPromotionalCampaign(customers: Array<{phone: string, name: string}>) {
    const promoText = '🎉 ¡50% de descuento en todos nuestros productos! Válido hasta el domingo. Código: PROMO50';
    
    const results = [];
    
    for (const customer of customers) {
      try {
        const result = await this.whatsappService.sendPromotionalMessage(
          customer.phone,
          customer.name,
          promoText,
        );
        
        results.push({
          customer: customer.name,
          phone: customer.phone,
          success: result.success,
          messageId: result.messageId,
          error: result.error,
        });

        // Pausa entre mensajes para evitar límites de rate
        await new Promise(resolve => setTimeout(resolve, 1000));
        
      } catch (error) {
        results.push({
          customer: customer.name,
          phone: customer.phone,
          success: false,
          error: error.message,
        });
      }
    }
    
    return results;
  }

  /**
   * Ejemplo 5: Notificación personalizada
   */
  async sendCustomNotification(
    customerPhone: string,
    message: string,
  ) {
    const formattedPhone = this.whatsappService.formatPhoneNumber(customerPhone);
    
    return await this.whatsappService.sendMessage({
      to: formattedPhone,
      body: message,
    });
  }

  /**
   * Ejemplo 6: Envío de mensaje con validación de teléfono
   */
  async sendMessageWithValidation(
    customerPhone: string,
    customerName: string,
    message: string,
  ) {
    // Formatear el número
    const formattedPhone = this.whatsappService.formatPhoneNumber(customerPhone);
    
    // Validar el número
    if (!this.whatsappService.validatePhoneNumber(formattedPhone)) {
      return {
        success: false,
        error: `Número de teléfono inválido: ${customerPhone}`,
      };
    }

    // Enviar mensaje
    return await this.whatsappService.sendMessage({
      to: formattedPhone,
      body: `Hola ${customerName}, ${message}`,
    });
  }
}

/**
 * Ejemplos de uso en controladores
 */

// En tu controlador de webhooks de Stripe:
/*
@Post('stripe/webhook')
async handleStripeWebhook(@Body() event: any) {
  if (event.type === 'payment_intent.succeeded') {
    await this.whatsappIntegrationExample.onStripePaymentSuccess(event);
  }
}
*/

// En tu controlador de clientes:
/*
@Post('customers')
async createCustomer(@Body() customerData: any) {
  // Crear cliente en base de datos
  const customer = await this.customersService.create(customerData);
  
  // Enviar mensaje de bienvenida
  await this.whatsappIntegrationExample.welcomeNewCustomer(
    customer.phone,
    customer.name
  );
  
  return customer;
}
*/

// En tu controlador de órdenes:
/*
@Put('orders/:id/ship')
async shipOrder(@Param('id') id: string, @Body() shipmentData: any) {
  // Actualizar orden
  const order = await this.ordersService.ship(id, shipmentData);
  
  // Notificar por WhatsApp
  await this.whatsappIntegrationExample.onOrderShipped({
    customerPhone: order.customer.phone,
    customerName: order.customer.name,
    orderId: order.id,
    trackingNumber: shipmentData.trackingNumber,
  });
  
  return order;
}
*/ 