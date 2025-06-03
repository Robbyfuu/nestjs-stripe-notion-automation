# 📱 Módulo WhatsApp para NestJS

Este módulo te permite enviar mensajes de WhatsApp a tus clientes usando dos proveedores diferentes:

- **Twilio** (recomendado para empezar): Más fácil de configurar
- **Meta WhatsApp Business API** (más funcionalidades): Soporte para templates y más opciones

## 🚀 Características

- ✅ Envío de mensajes de texto
- ✅ Validación y formateo de números telefónicos
- ✅ Mensajes predefinidos (bienvenida, confirmación de pago, envío)
- ✅ Mensajes promocionales
- ✅ Soporte para templates (Meta API)
- ✅ Integración con Stripe y Notion
- ✅ Logging completo
- ✅ DTOs para validación
- ✅ Gestión segura con 1Password

## 📋 Configuración

### 1. Instalar dependencias

```bash
pnpm install
```

Las dependencias `twilio`, `axios`, `class-validator` y `class-transformer` ya están incluidas.

### 2. Configurar variables de entorno con 1Password

🔒 **Este proyecto usa 1Password** para gestionar las variables de entorno de forma segura.

#### Configuración interactiva (recomendado):

```bash
pnpm run setup:interactive
```

Luego selecciona la opción **"w. Configuración rápida (WhatsApp)"**

#### Configuración por pasos:

**Opción A: Solo Twilio (recomendado para empezar)**
```bash
pnpm run setup:interactive
# Selecciona: w > 1
```

**Opción B: Solo Meta WhatsApp Business API**
```bash
pnpm run setup:interactive
# Selecciona: w > 2
```

**Opción C: Configurar ambos proveedores**
```bash
pnpm run setup:interactive
# Selecciona: w > 3
```

### 3. Variables que se configuran en 1Password

El script creará las siguientes entradas en 1Password:

#### 📱 NestJS WhatsApp Twilio
- **Account SID**: Tu Account SID de Twilio (empieza con `AC`)
- **Auth Token**: Tu Auth Token de Twilio
- **WhatsApp From**: Número de WhatsApp sandbox (`+14155238886` para desarrollo)

#### 📱 NestJS WhatsApp Meta
- **Use Meta API**: `true` o `false` para activar Meta API
- **Access Token**: Token de acceso de Meta WhatsApp Business API
- **Phone Number ID**: ID del número de teléfono verificado en Meta

### 4. Guías de configuración por proveedor

#### Opción A: Configurar Twilio (Fácil)

1. **Crear cuenta en Twilio**:
   - Ve a [Twilio Console](https://console.twilio.com/)
   - Crea una cuenta gratuita

2. **Activar WhatsApp Sandbox**:
   - Ve a "Develop > Messaging > Try it out > Send a WhatsApp message"
   - Sigue las instrucciones para activar el sandbox
   - Anota el número de sandbox: `+14155238886`

3. **Obtener credenciales**:
   - Account SID y Auth Token están en el Dashboard principal

4. **Configurar con el script**:
   ```bash
   pnpm run setup:interactive
   # Selecciona: w > 1 (Solo Twilio)
   ```

#### Opción B: Configurar Meta WhatsApp Business API (Avanzado)

1. **Crear app en Facebook Developers**:
   - Ve a [Facebook Developers](https://developers.facebook.com/)
   - Crea una nueva app

2. **Agregar producto WhatsApp**:
   - En tu app, agrega "WhatsApp Business"
   - Completa la configuración del producto

3. **Verificar número de teléfono**:
   - Agrega y verifica tu número de WhatsApp Business

4. **Obtener credenciales**:
   - Access Token (temporal o permanente)
   - Phone Number ID

5. **Configurar con el script**:
   ```bash
   pnpm run setup:interactive
   # Selecciona: w > 2 (Solo Meta API)
   ```

## 🔧 Uso

### API Endpoints

#### Enviar mensaje simple
```http
POST /whatsapp/send
Content-Type: application/json

{
  "to": "+5215551234567",
  "body": "¡Hola! Este es un mensaje de prueba."
}
```

#### Mensaje de bienvenida
```http
POST /whatsapp/welcome
Content-Type: application/json

{
  "phone": "5551234567",
  "name": "Juan Pérez"
}
```

#### Confirmación de pago
```http
POST /whatsapp/payment-confirmation
Content-Type: application/json

{
  "phone": "+5215551234567",
  "name": "Juan Pérez",
  "amount": 299.99,
  "orderId": "ORD-12345"
}
```

#### Notificación de envío
```http
POST /whatsapp/shipment-notification
Content-Type: application/json

{
  "phone": "+5215551234567",
  "name": "Juan Pérez",
  "orderId": "ORD-12345",
  "trackingNumber": "1Z999AA1234567890"
}
```

#### Mensaje promocional
```http
POST /whatsapp/promotional
Content-Type: application/json

{
  "phone": "+5215551234567",
  "name": "Juan Pérez",
  "promoText": "50% de descuento en todos los productos. Código: PROMO50"
}
```

#### Validar número telefónico
```http
GET /whatsapp/validate-phone/5551234567
```

### Uso programático

```typescript
import { WhatsappService } from './whatsapp/whatsapp.service';

@Injectable()
export class MiServicio {
  constructor(private whatsappService: WhatsappService) {}

  async notificarPago(customerPhone: string, customerName: string, amount: number, orderId: string) {
    const result = await this.whatsappService.sendPaymentConfirmation(
      customerPhone,
      customerName,
      amount,
      orderId
    );

    if (result.success) {
      console.log('✅ Mensaje enviado:', result.messageId);
    } else {
      console.error('❌ Error:', result.error);
    }
  }
}
```

## 🔌 Integración con Stripe

Ejemplo de integración en webhook de Stripe:

```typescript
@Post('stripe/webhook')
async handleStripeWebhook(@Body() event: any) {
  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    
    // Obtener datos del cliente de tu base de datos
    const customer = await this.customersService.findByEmail(paymentIntent.receipt_email);
    
    // Enviar notificación WhatsApp
    await this.whatsappService.sendPaymentConfirmation(
      customer.phone,
      customer.name,
      paymentIntent.amount / 100,
      paymentIntent.id
    );
  }
}
```

## 📱 Formatos de números telefónicos

El servicio acepta números en varios formatos y los convierte automáticamente al formato internacional:

```typescript
// Formatos aceptados:
"5551234567"       // Se convierte a "+525551234567"
"045551234567"     // Se convierte a "+525551234567"  
"+525551234567"    // Ya está en formato correcto
"(555) 123-4567"   // Se convierte a "+525551234567"
```

## 🎨 Mensajes predefinidos

El servicio incluye varios tipos de mensajes predefinidos:

- **Bienvenida**: Para nuevos clientes
- **Confirmación de pago**: Cuando se procesa un pago
- **Notificación de envío**: Cuando se envía un pedido
- **Promocional**: Para campañas de marketing

## 📊 Logging

Todos los mensajes enviados se registran en los logs:

```
[WhatsappService] Mensaje enviado via Twilio: SM1234567890abcdef
[WhatsappController] Enviando mensaje a +5215551234567
```

## ❌ Manejo de errores

El servicio devuelve respuestas consistentes:

```typescript
// Éxito
{
  "success": true,
  "messageId": "SM1234567890abcdef"
}

// Error
{
  "success": false,
  "error": "Número de teléfono inválido"
}
```

## 🔒 Seguridad con 1Password

### Ventajas del sistema actual:

- ✅ **Variables encriptadas**: Todas las credenciales están seguras en 1Password
- ✅ **No archivos .env**: Sin archivos sensibles en el repositorio
- ✅ **Ambientes separados**: Variables diferentes para dev/prod automáticamente
- ✅ **Acceso controlado**: Solo usuarios autorizados pueden ver las credenciales
- ✅ **Auditoría**: 1Password registra quién accede a qué y cuándo

### Comandos útiles:

```bash
# Ver estado de todas las variables
pnpm run setup:interactive
# Selecciona: v (Ver valores actuales)

# Configurar solo WhatsApp
pnpm run setup:interactive
# Selecciona: w (Configuración WhatsApp)

# Actualizar una variable específica
pnpm run setup:interactive
# Selecciona: 12-17 (Variables WhatsApp específicas)
```

## 🚀 Iniciar la aplicación

Una vez configuradas las variables:

```bash
# Desarrollo
pnpm run start:dev

# Producción
pnpm run start:prod
```

## 🛠️ Troubleshooting

### Error: "No hay proveedor de WhatsApp configurado"
```bash
# Verificar que las variables estén configuradas
pnpm run setup:interactive
# Selecciona: v (Ver valores)
```

### Error: "Número de teléfono inválido"
- Usa formato internacional: `+[código país][número]`
- Para México: `+5215551234567`

### Mensajes no llegan (Twilio)
1. Verifica que el número de destino esté registrado en el sandbox
2. Ve a Twilio Console > WhatsApp Sandbox > Sandbox Participants
3. Confirma que las credenciales sean correctas en 1Password

### Mensajes no llegan (Meta API)
1. Verifica que el Access Token sea válido
2. Confirma que el Phone Number ID sea correcto
3. Asegúrate de que el número de destino esté en la lista de testers (en desarrollo)

## 📞 Soporte

Si tienes problemas:

1. **Revisa los logs** de la aplicación
2. **Verifica la configuración** con `pnpm run setup:interactive > v`
3. **Consulta la documentación** oficial:
   - [Twilio WhatsApp](https://www.twilio.com/docs/whatsapp)
   - [Meta WhatsApp Business API](https://developers.facebook.com/docs/whatsapp)
4. **Revisa el estado** del servicio con `GET /whatsapp/status` 