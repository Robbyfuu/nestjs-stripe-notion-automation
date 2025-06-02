# NestJS Stripe Notion WhatsApp Automation

Sistema de automatización que conecta pagos de Stripe con bases de datos de Notion y notificaciones WhatsApp.

## ⚡ Inicio Rápido

### 1. Configuración Inicial
```bash
# Instalar dependencias
pnpm install

# Configurar integración de Notion (compartida)
pnpm run setup:notion

# Configurar credenciales de DESARROLLO
pnpm run setup:dev

# Configurar credenciales de PRODUCCIÓN (opcional)
pnpm run setup:prod
```

### 2. Desarrollo Local
```bash
# Desarrollo local sin Docker (recomendado)
pnpm run dev:local

# Desarrollo con Docker
pnpm run docker:dev
```

### 3. Testing y Producción
```bash
# Testing con Docker
pnpm run docker:test

# Producción local con Docker
pnpm run docker:prod
```

## 🔧 Comandos Principales

| Comando | Descripción |
|---------|-------------|
| `pnpm run dev:local` | **🚀 Desarrollo local directo** |
| `pnpm run docker:dev` | Desarrollo con Docker |
| `pnpm run docker:test` | Testing con Docker |
| `pnpm run docker:prod` | Producción con Docker |
| `pnpm run setup:notion` | Configurar integración de Notion |
| `pnpm run setup:dev` | Configurar credenciales DEV |
| `pnpm run setup:prod` | Configurar credenciales PROD |
| `pnpm run setup:interactive` | Gestor interactivo de variables |
| `pnpm run docker:down` | Detener todos los contenedores |
| `pnpm run docker:logs:dev` | Ver logs de desarrollo |

## 🏗️ Arquitectura

```
Stripe Webhook → NestJS → Notion
                    ↓
              WhatsApp (Twilio)
```

1. **Webhook de Stripe** recibe evento de pago
2. **NestJS** procesa y valida el evento  
3. **Notion** guarda cliente y pago automáticamente
4. **WhatsApp** envía notificación al cliente

## 📱 WhatsApp Integration

### Configuración
- **Proveedor**: Twilio (configurado)
- **Número**: +14155238886
- **Sandbox**: Solo números registrados
- **API alternativa**: Meta WhatsApp (deshabilitada)

### Endpoints
```bash
# Enviar mensaje simple
POST /whatsapp/send
{
  "to": "+56996419674",
  "body": "¡Hola desde NestJS!"
}

# Mensaje de bienvenida
POST /whatsapp/welcome
{
  "to": "+56996419674",
  "customerName": "Roberto"
}

# Confirmación de pago
POST /whatsapp/payment-confirmation
{
  "to": "+56996419674",
  "customerName": "Roberto",
  "amount": 150.00,
  "paymentMethod": "tarjeta"
}

# Estado del servicio
GET /whatsapp/status
```

📚 **[Ver guía completa de WhatsApp →](WHATSAPP_SETUP.md)**

## 🐳 Entornos Docker

### Puertos configurados:
- **DEV**: Puerto 3000 (desarrollo)
- **TEST**: Puerto 3001 (testing)
- **PROD**: Puerto 3002 (producción)

### URLs locales:
- **Desarrollo**: `http://localhost:3000`
- **Testing**: `http://localhost:3001`
- **Producción**: `http://localhost:3002`

## 📋 Requisitos

- **Node.js 18+** y **pnpm**
- **1Password CLI** para gestión de secrets
- **Docker** (opcional, para contenedores)
- **Credenciales:**
  - Stripe API Key + Webhook Secret
  - Notion Integration Token + Database IDs
  - WhatsApp Twilio Account SID + Auth Token

## 🔑 Variables de Entorno

Gestionadas automáticamente por 1Password:

### 🧪 DESARROLLO
- `STRIPE_SECRET_KEY` → `NestJS Stripe API`
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases`
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases`
- `NOTION_CALENDAR_DATABASE_ID` → `NestJS Notion Databases`

### 🏭 PRODUCCIÓN
- `STRIPE_SECRET_KEY` → `NestJS Stripe API PROD` 
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook PROD`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases PROD`
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases PROD`
- `NOTION_CALENDAR_DATABASE_ID` → `NestJS Notion Databases PROD`

### 📚 COMPARTIDO
- `NOTION_SECRET` → `NestJS Notion Integration`
- `TWILIO_ACCOUNT_SID` → `NestJS WhatsApp Twilio`
- `TWILIO_AUTH_TOKEN` → `NestJS WhatsApp Twilio`
- `TWILIO_WHATSAPP_FROM` → `NestJS WhatsApp Twilio`

## 📝 Flujo de Desarrollo

### Desarrollo diario:
```bash
# 1. Desarrollo local rápido
pnpm run dev:local

# 2. Testing con Docker (cuando necesites)
pnpm run docker:test

# 3. Testing completo
curl http://localhost:3000/health
curl -X POST http://localhost:3000/whatsapp/send \
  -H "Content-Type: application/json" \
  -d '{"to": "+56996419674", "body": "Test local"}'
```

### Webhooks de Stripe locales:
```bash
# Terminal 1: Levantar la app
pnpm run dev:local

# Terminal 2: Stripe CLI para webhooks
stripe listen --forward-to localhost:3000/webhook/stripe
```

## 🆕 Funcionalidades

### 📅 Calendario Automático de Pagos
Cuando un cliente realiza un pago, el sistema automáticamente:
- ✅ Crea un evento en tu calendario de Notion
- 📋 Incluye detalles: cliente, monto, método de pago
- 🕒 Usa la fecha/hora exacta del pago
- 💰 Formato: `💰 Pago recibido - [Nombre Cliente]`

### 🎛️ Gestor Interactivo de Variables
```bash
pnpm run setup:interactive
```
**Características:**
- 🎨 Interfaz con colores y menús intuitivos
- 📊 Estado en tiempo real de todas las variables
- ⚡ Configuración rápida por ambiente
- 🔍 Visualización enmascarada de valores
- ✏️ Modificación individual de variables

## 🔧 Troubleshooting

### Problemas con Webhooks de Stripe
- **Error 500**: Verifica que el webhook secret sea correcto en 1Password
- **Firma inválida**: Confirma que la URL del webhook esté configurada correctamente
- **No recibe eventos**: Revisa que `payment_intent.succeeded` esté seleccionado

### Problemas con WhatsApp
- **Mensaje no se envía**: Verifica que el número esté registrado en Twilio sandbox
- **Error 401**: Confirma TWILIO_ACCOUNT_SID y TWILIO_AUTH_TOKEN en variables
- **Número inválido**: Usa formato internacional: +56996419674

### Problemas con 1Password
- **CLI no encontrado**: Instala con `brew install --cask 1password/tap/1password-cli`
- **No autenticado**: Ejecuta `eval $(op signin)` 
- **Credenciales no encontradas**: Verifica nombres exactos de las entradas

### Problemas con Docker
- **Error de permisos**: Asegúrate de que Docker esté corriendo
- **Variables no cargadas**: Verifica que 1Password CLI esté funcionando
- **Puerto ocupado**: Usa `pnpm run docker:down` para limpiar

## 📊 Health Checks

### Verificar servicios:
```bash
# Local
curl http://localhost:3000/health

# Docker DEV
curl http://localhost:3000/health

# Docker TEST  
curl http://localhost:3001/health

# Docker PROD
curl http://localhost:3002/health
```

### Estado de WhatsApp:
```bash
curl http://localhost:3000/whatsapp/status
```

## 📚 Documentación

- 📱 **[WhatsApp Setup Guide](WHATSAPP_SETUP.md)** - Integración de WhatsApp con Twilio
- 🐳 **[Docker Guide](README-DOCKER.md)** - Desarrollo con Docker
- 📖 **[Development Guide](DEVELOPMENT.md)** - Workflow de desarrollo
- 🏗️ **[Technical Docs](docs/)** - Arquitectura y diagramas

---

**Desarrollado con NestJS + Stripe + Notion + WhatsApp + 1Password + Docker**

