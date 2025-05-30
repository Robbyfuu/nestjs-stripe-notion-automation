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