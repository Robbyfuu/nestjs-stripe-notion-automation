# NestJS + Stripe + Notion Automation

Integración automática de pagos de Stripe con bases de datos de Notion para gestión de clientes y pagos.

## Descripción

Este proyecto automatiza el registro de pagos de Stripe en bases de datos de Notion, creando y actualizando clientes automáticamente con Alpine Linux 3.21.

## Herramientas de Calidad de Código

Este proyecto utiliza [Biome](https://biomejs.dev/) para linting y formateo:

```bash
# Verificar formato, imports y linting
pnpm run check

# Aplicar correcciones automáticas
pnpm run check:fix

# Solo formatear código
pnpm run format

# Solo linting
pnpm run lint
```

## Configuración del Proyecto

```bash
pnpm install
```

## Variables de Entorno

Crea un archivo `.env` con:

```bash
PORT=3000
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NOTION_SECRET=secret_...
NOTION_PAYMENTS_DATABASE_ID=...
NOTION_CLIENTS_DATABASE_ID=...
```

## Obtener Tokens y Claves

### 🏦 Stripe Configuration

#### 1. Obtener Stripe Secret Key
1. Ve a [Stripe Dashboard](https://dashboard.stripe.com/)
2. Navega a **Developers** → **API keys**
3. Copia tu **Secret key** (empieza con `sk_test_` para pruebas o `sk_live_` para producción)
4. Úsala como `STRIPE_SECRET_KEY` en tu `.env`

#### 2. Configurar Webhook de Stripe
1. En Stripe Dashboard, ve a **Developers** → **Webhooks**
2. Haz clic en **Add endpoint**
3. URL del endpoint: `https://tu-dominio.com/webhook/stripe`
4. Selecciona eventos: `payment_intent.succeeded`
5. Copia el **Signing secret** (empieza con `whsec_`)
6. Úsalo como `STRIPE_WEBHOOK_SECRET` en tu `.env`

### 📝 Notion Configuration

#### 1. Crear Integración de Notion
1. Ve a [Notion Developers](https://www.notion.so/my-integrations)
2. Haz clic en **New integration**
3. Completa los detalles:
   - **Name**: NestJS Stripe Integration
   - **Logo**: Opcional
   - **Associated workspace**: Selecciona tu workspace
4. Copia el **Internal Integration Secret** (empieza con `secret_`)
5. Úsalo como `NOTION_SECRET` en tu `.env`

#### 2. Crear y Configurar Bases de Datos

##### Base de Datos de Clientes
1. Crea una nueva página en Notion
2. Agrega una base de datos con estas propiedades:
   - **Name** (Title)
   - **Email** (Email)
   - **Stripe Customer ID** (Rich Text)
   - **Created At** (Date)
3. Comparte la página con tu integración:
   - Haz clic en **Share** → **Add people**
   - Busca tu integración y dale acceso
4. Copia el ID de la base de datos de la URL: `notion.so/workspace/DATABASE_ID?v=...`
5. Úsalo como `NOTION_CLIENTS_DATABASE_ID`

##### Base de Datos de Pagos
1. Crea otra página/base de datos con estas propiedades:
   - **Payment ID** (Title)
   - **Customer** (Relation to Clients DB)
   - **Amount** (Number)
   - **Currency** (Select)
   - **Status** (Select: succeeded, failed, pending)
   - **Payment Date** (Date)
   - **Stripe Payment Intent ID** (Rich Text)
2. Comparte con tu integración igual que antes
3. Copia el ID y úsalo como `NOTION_PAYMENTS_DATABASE_ID`

#### 3. IDs de Base de Datos
Los IDs están en la URL de la base de datos:
```
https://notion.so/workspace/DATABASE_ID?v=VIEW_ID
```
Solo necesitas la parte `DATABASE_ID` (32 caracteres alfanuméricos).

### 🔗 Ejemplo de Archivo .env Completo
```bash
PORT=3000
STRIPE_SECRET_KEY=sk_test_51AbCdEf1234567890
STRIPE_WEBHOOK_SECRET=whsec_1234567890abcdef
NOTION_SECRET=secret_AbCdEf1234567890
NOTION_PAYMENTS_DATABASE_ID=12345678901234567890123456789012
NOTION_CLIENTS_DATABASE_ID=09876543210987654321098765432109
```

## Ejecutar la Aplicación

```bash
# desarrollo
pnpm run start

# modo watch
pnpm run start:dev

# producción
pnpm run start:prod
```

## Pruebas

```bash
# pruebas unitarias
pnpm run test

# pruebas e2e
pnpm run test:e2e

# cobertura de pruebas
pnpm run test:cov
```

## Estructura del Proyecto

- `src/stripe/` - Integración con Stripe
- `src/notion/` - Integración con Notion
- `src/payments/` - Procesamiento de pagos
- `biome.json` - Configuración de Biome

## Endpoints

- `GET /` - Estado de la aplicación
- `GET /health` - Health check
- `POST /webhook/stripe` - Webhook de Stripe 