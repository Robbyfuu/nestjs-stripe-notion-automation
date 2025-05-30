import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client } from '@notionhq/client';

@Injectable()
export class NotionService {
  private notion: Client;
  private paymentsDbId: string;
  private clientsDbId: string;

  constructor(@Inject(ConfigService) private configService: ConfigService) {
    this.notion = new Client({
      auth: this.configService.get<string>('NOTION_SECRET')!,
    });
    this.paymentsDbId = this.configService.get<string>('NOTION_PAYMENTS_DATABASE_ID')!;
    this.clientsDbId = this.configService.get<string>('NOTION_CLIENTS_DATABASE_ID')!;
  }

  /**
   * Busca un cliente en la base de datos de Notion por su email
   */
  async findClientByEmail(email: string) {
    try {
      const response = await this.notion.databases.query({
        database_id: this.clientsDbId,
        filter: {
          property: 'Email',
          rich_text: {
            equals: email,
          },
        },
      });

      return response.results[0] || null;
    } catch (error) {
      console.error('Error buscando cliente en Notion:', error);
      throw error;
    }
  }

  /**
   * Crea o actualiza un cliente en la base de datos de clientes
   */
  async createOrUpdateClient(clientData: {
    name: string;
    email: string;
    phone?: string;
    lastPaymentDate: Date;
  }) {
    try {
      // Primero verificamos si el cliente ya existe
      const existingClient = await this.findClientByEmail(clientData.email);

      const properties: any = {
        Nombre: {
          title: [
            {
              text: {
                content: clientData.name,
              },
            },
          ],
        },
        Email: {
          email: clientData.email,
        },
        'Fecha Último Pago': {
          date: {
            start: clientData.lastPaymentDate.toISOString(),
          },
        },
        Categoría: {
          select: {
            name: 'Nuevo',
          },
        },
      };

      // Agregar teléfono si está disponible
      if (clientData.phone) {
        properties.Teléfono = {
          phone_number: clientData.phone,
        };
      }

      if (existingClient) {
        // Actualizar cliente existente
        return await this.notion.pages.update({
          page_id: existingClient.id,
          properties,
        });
      }

      // Crear nuevo cliente
      return await this.notion.pages.create({
        parent: {
          database_id: this.clientsDbId,
        },
        properties,
      });
    } catch (error) {
      console.error('Error creando/actualizando cliente en Notion:', error);
      throw error;
    }
  }

  /**
   * Registra un nuevo pago en la base de datos de pagos de Notion
   */
  async createPaymentRecord(paymentData: {
    paymentName: string; // Descripción del pago
    amount: number;
    currency: string;
    transactionId: string; // ID de transacción de Stripe
    paymentMethod: string;
    status: string;
    customerEmail: string;
    clientPageId?: string;
    date: Date;
  }) {
    try {
      const { paymentName, amount, currency, transactionId, paymentMethod, status, customerEmail, clientPageId, date } = paymentData;

      const properties: any = {
        'Nombre del Pago': {
          title: [
            {
              text: {
                content: paymentName,
              },
            },
          ],
        },
        Monto: {
          number: amount / 100, // Convertir centavos a unidades monetarias
        },
        Moneda: {
          select: {
            name: currency.toUpperCase(),
          },
        },
        'Fecha de Pago': {
          date: {
            start: date.toISOString(),
          },
        },
        'Correo electrónico': {
          email: customerEmail,
        },
        Estado: {
          select: {
            name: status === 'succeeded' ? 'Completado' : status,
          },
        },
        'ID de Transacción': {
          rich_text: [
            {
              text: {
                content: transactionId,
              },
            },
          ],
        },
        'Método de Pago': {
          select: {
            name: paymentMethod === 'card' ? 'card' : paymentMethod,
          },
        },
      };

      // Si tenemos una referencia al cliente, creamos la relación
      if (clientPageId) {
        properties.Cliente = {
          relation: [
            {
              id: clientPageId,
            },
          ],
        };
      }

      const response = await this.notion.pages.create({
        parent: {
          database_id: this.paymentsDbId,
        },
        properties,
      });

      return response;
    } catch (error) {
      console.error('Error creando registro de pago en Notion:', error);
      throw error;
    }
  }

  /**
   * Calcula y actualiza el total pagado por un cliente
   */
  async updateClientTotalPaid(clientPageId: string) {
    try {
      // Buscar todos los pagos del cliente
      const paymentsResponse = await this.notion.databases.query({
        database_id: this.paymentsDbId,
        filter: {
          property: 'Cliente',
          relation: {
            contains: clientPageId,
          },
        },
      });

      // Calcular el total
      let totalPaid = 0;
      for (const payment of paymentsResponse.results) {
        const properties = (payment as any).properties;
        const montoProperty = properties?.Monto;
        if (montoProperty && 'number' in montoProperty && montoProperty.number) {
          totalPaid += montoProperty.number;
        }
      }

      // Actualizar el cliente con el total
      await this.notion.pages.update({
        page_id: clientPageId,
        properties: {
          'Total Pagado': {
            number: totalPaid,
          },
        },
      });

      return totalPaid;
    } catch (error) {
      console.error('Error actualizando total pagado del cliente:', error);
      throw error;
    }
  }
}
