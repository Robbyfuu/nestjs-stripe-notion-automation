import { Controller, Post, Body, Get, Param, Logger } from '@nestjs/common';
import { WhatsappService } from './whatsapp.service';
import { WhatsappTemplate } from './interfaces/whatsapp.interface';
import {
  SendMessageDto,
  SendWelcomeDto,
  SendPaymentConfirmationDto,
  SendShipmentNotificationDto,
  SendPromotionalDto,
} from './dto/send-message.dto';

@Controller('whatsapp')
export class WhatsappController {
  private readonly logger = new Logger(WhatsappController.name);

  constructor(private readonly whatsappService: WhatsappService) {}

  @Post('send')
  async sendMessage(@Body() message: SendMessageDto) {
    this.logger.log(`Enviando mensaje a ${message.to}`);
    
    if (!this.whatsappService.validatePhoneNumber(message.to)) {
      return {
        success: false,
        error: 'Número de teléfono inválido. Use formato internacional (+52XXXXXXXXXX)',
      };
    }

    return await this.whatsappService.sendMessage(message);
  }

  @Post('send-template')
  async sendTemplate(
    @Body() body: { to: string; template: WhatsappTemplate },
  ) {
    this.logger.log(`Enviando template ${body.template.name} a ${body.to}`);
    
    if (!this.whatsappService.validatePhoneNumber(body.to)) {
      return {
        success: false,
        error: 'Número de teléfono inválido. Use formato internacional (+52XXXXXXXXXX)',
      };
    }

    return await this.whatsappService.sendTemplateMessage(body.to, body.template);
  }

  @Post('welcome')
  async sendWelcome(@Body() body: SendWelcomeDto) {
    this.logger.log(`Enviando mensaje de bienvenida a ${body.name}`);
    
    const formattedPhone = this.whatsappService.formatPhoneNumber(body.phone);
    
    if (!this.whatsappService.validatePhoneNumber(formattedPhone)) {
      return {
        success: false,
        error: 'Número de teléfono inválido. Use formato internacional (+52XXXXXXXXXX)',
      };
    }

    return await this.whatsappService.sendWelcomeMessage(formattedPhone, body.name);
  }

  @Post('payment-confirmation')
  async sendPaymentConfirmation(@Body() body: SendPaymentConfirmationDto) {
    this.logger.log(`Enviando confirmación de pago para orden ${body.orderId}`);
    
    const formattedPhone = this.whatsappService.formatPhoneNumber(body.phone);
    
    if (!this.whatsappService.validatePhoneNumber(formattedPhone)) {
      return {
        success: false,
        error: 'Número de teléfono inválido. Use formato internacional (+52XXXXXXXXXX)',
      };
    }

    return await this.whatsappService.sendPaymentConfirmation(
      formattedPhone,
      body.name,
      body.amount,
      body.orderId,
    );
  }

  @Post('shipment-notification')
  async sendShipmentNotification(@Body() body: SendShipmentNotificationDto) {
    this.logger.log(`Enviando notificación de envío para orden ${body.orderId}`);
    
    const formattedPhone = this.whatsappService.formatPhoneNumber(body.phone);
    
    if (!this.whatsappService.validatePhoneNumber(formattedPhone)) {
      return {
        success: false,
        error: 'Número de teléfono inválido. Use formato internacional (+52XXXXXXXXXX)',
      };
    }

    return await this.whatsappService.sendShipmentNotification(
      formattedPhone,
      body.name,
      body.orderId,
      body.trackingNumber,
    );
  }

  @Post('promotional')
  async sendPromotional(@Body() body: SendPromotionalDto) {
    this.logger.log(`Enviando mensaje promocional a ${body.name}`);
    
    const formattedPhone = this.whatsappService.formatPhoneNumber(body.phone);
    
    if (!this.whatsappService.validatePhoneNumber(formattedPhone)) {
      return {
        success: false,
        error: 'Número de teléfono inválido. Use formato internacional (+52XXXXXXXXXX)',
      };
    }

    return await this.whatsappService.sendPromotionalMessage(
      formattedPhone,
      body.name,
      body.promoText,
    );
  }

  @Get('validate-phone/:phone')
  validatePhone(@Param('phone') phone: string) {
    const formattedPhone = this.whatsappService.formatPhoneNumber(phone);
    const isValid = this.whatsappService.validatePhoneNumber(formattedPhone);
    
    return {
      original: phone,
      formatted: formattedPhone,
      isValid,
    };
  }

  @Get('status')
  getStatus() {
    return {
      service: 'WhatsApp Service',
      status: 'active',
      timestamp: new Date().toISOString(),
    };
  }
} 