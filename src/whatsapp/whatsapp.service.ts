import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Twilio } from 'twilio';
import axios from 'axios';
import {
  WhatsappMessage,
  WhatsappTemplate,
  WhatsappResponse,
} from './interfaces/whatsapp.interface';

@Injectable()
export class WhatsappService {
  private readonly logger = new Logger(WhatsappService.name);
  private readonly twilioClient: Twilio;
  private readonly useMetaAPI: boolean;
  private readonly metaAccessToken: string;
  private readonly metaPhoneNumberId: string;

  constructor(private configService: ConfigService) {
    // Configuración de Twilio
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN');
    
    if (accountSid && authToken) {
      this.twilioClient = new Twilio(accountSid, authToken);
    }

    // Configuración de Meta WhatsApp Business API
    this.useMetaAPI = this.configService.get<boolean>('USE_META_WHATSAPP_API', false);
    this.metaAccessToken = this.configService.get<string>('META_WHATSAPP_ACCESS_TOKEN');
    this.metaPhoneNumberId = this.configService.get<string>('META_WHATSAPP_PHONE_NUMBER_ID');
  }

  /**
   * Envía un mensaje de texto simple por WhatsApp
   */
  async sendMessage(message: WhatsappMessage): Promise<WhatsappResponse> {
    try {
      if (this.useMetaAPI && this.metaAccessToken) {
        return await this.sendMessageViaMeta(message);
      }
      if (this.twilioClient) {
        return await this.sendMessageViaTwilio(message);
      }
      throw new Error('No hay proveedor de WhatsApp configurado');
    } catch (error) {
      this.logger.error('Error enviando mensaje WhatsApp:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Envía un mensaje usando un template predefinido
   */
  async sendTemplateMessage(
    to: string,
    template: WhatsappTemplate,
  ): Promise<WhatsappResponse> {
    try {
      if (this.useMetaAPI && this.metaAccessToken) {
        return await this.sendTemplateViaMeta(to, template);
      }
      throw new Error('Los templates solo están disponibles con Meta WhatsApp Business API');
    } catch (error) {
      this.logger.error('Error enviando template WhatsApp:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Envía un mensaje de bienvenida a un nuevo cliente
   */
  async sendWelcomeMessage(customerPhone: string, customerName: string): Promise<WhatsappResponse> {
    const welcomeMessage: WhatsappMessage = {
      to: customerPhone,
      body: `¡Hola ${customerName}! 👋\n\nGracias por tu compra. Te mantendremos informado sobre el estado de tu pedido.\n\n¿Necesitas ayuda? Solo responde a este mensaje.`,
    };

    return await this.sendMessage(welcomeMessage);
  }

  /**
   * Envía notificación de pago exitoso
   */
  async sendPaymentConfirmation(
    customerPhone: string,
    customerName: string,
    amount: number,
    orderId: string,
  ): Promise<WhatsappResponse> {
    const paymentMessage: WhatsappMessage = {
      to: customerPhone,
      body: `✅ ¡Pago confirmado!\n\nHola ${customerName},\n\nHemos recibido tu pago de $${amount} para el pedido #${orderId}.\n\nTe notificaremos cuando tu pedido esté listo para envío.`,
    };

    return await this.sendMessage(paymentMessage);
  }

  /**
   * Envía notificación de pedido enviado
   */
  async sendShipmentNotification(
    customerPhone: string,
    customerName: string,
    orderId: string,
    trackingNumber?: string,
  ): Promise<WhatsappResponse> {
    let body = `📦 ¡Tu pedido está en camino!\n\nHola ${customerName},\n\nTu pedido #${orderId} ha sido enviado.`;
    
    if (trackingNumber) {
      body += `\n\nNúmero de seguimiento: ${trackingNumber}`;
    }
    
    body += '\n\n¡Pronto lo tendrás en tus manos!';

    const shipmentMessage: WhatsappMessage = {
      to: customerPhone,
      body,
    };

    return await this.sendMessage(shipmentMessage);
  }

  /**
   * Envía mensaje promocional
   */
  async sendPromotionalMessage(
    customerPhone: string,
    customerName: string,
    promoText: string,
  ): Promise<WhatsappResponse> {
    const promoMessage: WhatsappMessage = {
      to: customerPhone,
      body: `🎉 ¡Oferta especial para ti, ${customerName}!\n\n${promoText}\n\n¿Interesado? Solo responde a este mensaje.`,
    };

    return await this.sendMessage(promoMessage);
  }

  /**
   * Implementación privada para Twilio
   */
  private async sendMessageViaTwilio(message: WhatsappMessage): Promise<WhatsappResponse> {
    const twilioFrom = this.configService.get<string>('TWILIO_WHATSAPP_FROM');
    
    if (!twilioFrom) {
      throw new Error('TWILIO_WHATSAPP_FROM no está configurado');
    }

    const twilioMessage = await this.twilioClient.messages.create({
      body: message.body,
      from: `whatsapp:${twilioFrom}`,
      to: `whatsapp:${message.to}`,
    });

    this.logger.log(`Mensaje enviado via Twilio: ${twilioMessage.sid}`);

    return {
      success: true,
      messageId: twilioMessage.sid,
    };
  }

  /**
   * Implementación privada para Meta WhatsApp Business API
   */
  private async sendMessageViaMeta(message: WhatsappMessage): Promise<WhatsappResponse> {
    const url = `https://graph.facebook.com/v18.0/${this.metaPhoneNumberId}/messages`;
    
    const payload = {
      messaging_product: 'whatsapp',
      to: message.to,
      type: 'text',
      text: {
        body: message.body,
      },
    };

    const response = await axios.post(url, payload, {
      headers: {
        'Authorization': `Bearer ${this.metaAccessToken}`,
        'Content-Type': 'application/json',
      },
    });

    this.logger.log(`Mensaje enviado via Meta API: ${response.data.messages[0].id}`);

    return {
      success: true,
      messageId: response.data.messages[0].id,
    };
  }

  /**
   * Implementación privada para templates de Meta
   */
  private async sendTemplateViaMeta(
    to: string,
    template: WhatsappTemplate,
  ): Promise<WhatsappResponse> {
    const url = `https://graph.facebook.com/v18.0/${this.metaPhoneNumberId}/messages`;
    
    const payload = {
      messaging_product: 'whatsapp',
      to: to,
      type: 'template',
      template: {
        name: template.name,
        language: {
          code: template.language,
        },
        components: template.components || [],
      },
    };

    const response = await axios.post(url, payload, {
      headers: {
        'Authorization': `Bearer ${this.metaAccessToken}`,
        'Content-Type': 'application/json',
      },
    });

    this.logger.log(`Template enviado via Meta API: ${response.data.messages[0].id}`);

    return {
      success: true,
      messageId: response.data.messages[0].id,
    };
  }

  /**
   * Valida si el número de teléfono está en formato correcto
   */
  validatePhoneNumber(phoneNumber: string): boolean {
    // Formato internacional: +[código país][número]
    const phoneRegex = /^\+[1-9]\d{1,14}$/;
    return phoneRegex.test(phoneNumber);
  }

  /**
   * Formatea un número de teléfono al formato internacional
   */
  formatPhoneNumber(phoneNumber: string, countryCode = '+52'): string {
    // Eliminar espacios, guiones y paréntesis
    let cleaned = phoneNumber.replace(/[\s\-\(\)]/g, '');
    
    // Si no tiene código de país, agregarlo
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      cleaned = countryCode + cleaned;
    }

    return cleaned;
  }
} 