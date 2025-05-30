# Guía de Configuración

## Requisitos Previos

- Node.js 20+
- pnpm
- Docker y Docker Compose (opcional)

## Configuración Inicial

### 1. Clonar e instalar dependencias

```bash
git clone <tu-repositorio>
cd nestjs-stripe
pnpm install
```

### 2. Configurar variables de entorno

Copia el archivo de template y configura tus variables:

```bash
cp env.template .env
```

Edita `.env` con tus valores reales:

```bash
# Configuración del servidor
PORT=3000
NODE_ENV=development

# Configuración de Stripe
STRIPE_SECRET_KEY=sk_test_tu_clave_secreta_aqui
STRIPE_WEBHOOK_SECRET=whsec_tu_webhook_secret_aqui

# Configuración de Notion
NOTION_SECRET=secret_tu_integration_secret_aqui
NOTION_PAYMENTS_DATABASE_ID=tu_database_id_de_pagos
NOTION_CLIENTS_DATABASE_ID=tu_database_id_de_clientes
```

### 3. Configurar Stripe

1. Ve a [Stripe Dashboard](https://dashboard.stripe.com/)
2. Obtén tu clave secreta desde "Developers > API keys"
3. Configura el webhook:
   - Ve a "Developers > Webhooks"
   - Añade endpoint: `https://tu-dominio.com/webhook/stripe`
   - Eventos: `payment_intent.succeeded`
   - Copia el secret del webhook

### 4. Configurar Notion

1. Ve a [Notion Integrations](https://www.notion.so/my-integrations)
2. Crea una nueva integración
3. Obtén el "Internal Integration Token"
4. Crea dos bases de datos en Notion:

#### Base de Datos "Clientes"
Propiedades:
- `Nombre` (Title)
- `Email` (Email)
- `Teléfono` (Phone)
- `Total Pagado` (Number)
- `Fecha Último Pago` (Date)
- `Categoría` (Select: Nuevo, Recurrente, VIP)

#### Base de Datos "Pagos de Stripe"
Propiedades:
- `Nombre del Pago` (Title)
- `Monto` (Number)
- `Moneda` (Select: USD, EUR, etc.)
- `Fecha de Pago` (Date)
- `Correo electrónico` (Email)
- `Cliente` (Relation a base de datos Clientes)
- `Estado` (Select: Completado, Pendiente, Fallido)
- `ID de Transacción` (Text)
- `Método de Pago` (Select: card, bank_transfer, etc.)

5. Comparte ambas bases de datos con tu integración
6. Copia los IDs de las bases de datos desde las URLs

## Desarrollo

### Ejecutar localmente

```bash
# Modo desarrollo con hot reload
pnpm run start:dev

# Modo debug
pnpm run start:debug
```

### Con Docker

```bash
# Desarrollo
pnpm run docker:up:dev

# Producción
pnpm run docker:up

# Ver logs
pnpm run docker:logs
```

## Scripts Disponibles

### Desarrollo
- `pnpm run start:dev` - Servidor con hot reload
- `pnpm run start:debug` - Servidor con debugging
- `pnpm run build` - Build de producción

### Calidad de Código
- `pnpm run check` - Verificar formato y linting
- `pnpm run check:fix` - Corregir automáticamente
- `pnpm run format` - Solo formateo
- `pnpm run lint` - Solo linting

### Docker
- `pnpm run docker:build` - Build imagen de producción
- `pnpm run docker:up` - Levantar en producción
- `pnpm run docker:up:dev` - Levantar en desarrollo
- `pnpm run docker:down` - Parar contenedores

### Tests
- `pnpm run test` - Tests unitarios
- `pnpm run test:cov` - Tests con cobertura
- `pnpm run test:e2e` - Tests end-to-end

## Estructura del Proyecto

```
├── src/
│   ├── app.module.ts          # Módulo principal
│   ├── main.ts                # Punto de entrada
│   ├── notion/                # Integración con Notion
│   ├── payments/              # Procesamiento de pagos
│   └── stripe/                # Integración con Stripe
├── scripts/
│   └── health-check.js        # Health check para Docker
├── docker-compose.yml         # Configuración Docker producción
├── docker-compose.dev.yml     # Configuración Docker desarrollo
├── Dockerfile                 # Multi-stage build
├── biome.json                 # Configuración Biome
└── env.template               # Template variables de entorno
```

## Endpoints

- `GET /` - Estado de la aplicación
- `GET /health` - Health check
- `POST /webhook/stripe` - Webhook de Stripe

## Troubleshooting

### Error de permisos en Notion
- Verifica que la integración tenga acceso a las bases de datos
- Revisa que los IDs de las bases de datos sean correctos

### Error de webhook de Stripe
- Verifica que el webhook secret sea correcto
- Revisa que la URL del webhook esté configurada correctamente
- Verifica que el evento `payment_intent.succeeded` esté seleccionado

### Error de formato de código
- Ejecuta `pnpm run check:fix` para corregir automáticamente
- Si persiste, revisa la configuración en `biome.json` 