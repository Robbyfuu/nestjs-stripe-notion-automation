# NestJS Stripe Notion Automation

Sistema de automatización que conecta pagos de Stripe con bases de datos de Notion.

## ⚡ Inicio Rápido

### 1. Configuración Inicial
```bash
# Instalar dependencias
pnpm install

# Configurar integración de Notion (compartida)
pnpm run setup:notion

# Configurar credenciales de DESARROLLO
pnpm run setup:dev

# Configurar credenciales de PRODUCCIÓN
pnpm run setup:prod
```

### 2. Desarrollo
```bash
# Desarrollo completo (Docker + Stripe webhooks)
pnpm run dev

# Solo aplicación en Docker
pnpm run docker:dev
```

### 3. Deployment Automático
```bash
# Push a develop → Deploy automático a staging
git push origin develop

# Merge a main → Deploy automático a producción
git push origin main
```

## 🔧 Comandos Principales

| Comando | Descripción |
|---------|-------------|
| `pnpm run setup:notion` | Configurar integración de Notion (compartida) |
| `pnpm run setup:dev` | Configurar credenciales de **DESARROLLO** |
| `pnpm run setup:prod` | Configurar credenciales de **PRODUCCIÓN** |
| `pnpm run setup:interactive` | **🆕 Gestor interactivo de variables** |
| `pnpm run dev` | Desarrollo completo con webhooks |
| `pnpm run prod` | **Producción local con verificaciones** |
| `pnpm run deploy:dev` | **🚀 Deploy manual a staging** |
| `pnpm run deploy:prod` | **🚀 Deploy manual a producción** |
| `pnpm run fly:logs:dev` | Ver logs de staging |
| `pnpm run fly:logs:prod` | Ver logs de producción |
| `pnpm run fly:status:dev` | Estado de staging |
| `pnpm run fly:status:prod` | Estado de producción |
| `pnpm run docker:dev` | Solo aplicación en Docker (desarrollo) |
| `pnpm run docker:prod` | Solo aplicación en Docker (producción) |
| `pnpm run docker:down` | Detener contenedores |
| `pnpm run docker:logs` | Ver logs de Docker |

## 🏗️ Arquitectura

```
Stripe Webhook → NestJS → Notion
```

1. **Webhook de Stripe** recibe evento de pago
2. **NestJS** procesa y valida el evento  
3. **Notion** guarda cliente y pago automáticamente

## 🌍 Ambientes

### 🧪 Development (Staging)
- **App**: `nestjs-stripe-notion-dev.fly.dev`
- **Branch**: `develop`
- **Deploy**: Automático en push a `develop`
- **Stripe**: Claves de TEST (`sk_test_`)
- **Notion**: Bases de datos de desarrollo

### 🏭 Production
- **App**: `nestjs-stripe-notion.fly.dev`
- **Branch**: `main`
- **Deploy**: Automático en merge a `main`
- **Stripe**: Claves REALES (`sk_live_`)
- **Notion**: Bases de datos de producción

## 📋 Requisitos

- **1Password CLI** para gestión de secrets
- **Stripe CLI** para webhooks de desarrollo
- **Docker** para contenedores
- **GitHub** para deployment automático
- **Credenciales:**
  - Stripe API Key + Webhook Secret (por ambiente)
  - Notion Integration Token + Database IDs (por ambiente)

## 🔑 Variables de Entorno

Gestionadas automáticamente por 1Password **separadas por ambiente**:

### 🧪 DESARROLLO (Development/Staging)
- `STRIPE_SECRET_KEY` → `NestJS Stripe API`
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases`
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases`
- `NOTION_CALENDAR_DATABASE_ID` → `NestJS Notion Databases` 🆕

### 🏭 PRODUCCIÓN
- `STRIPE_SECRET_KEY` → `NestJS Stripe API PROD` 
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook PROD`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases PROD`
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases PROD`
- `NOTION_CALENDAR_DATABASE_ID` → `NestJS Notion Databases PROD` 🆕

### 📚 COMPARTIDO (Ambos ambientes)
- `NOTION_SECRET` → `NestJS Notion Integration`

## 📝 Flujo de Trabajo

1. Cliente realiza pago en Stripe
2. Stripe envía webhook a `/webhook/stripe`
3. Sistema verifica firma del webhook
4. Extrae datos del cliente y pago
5. Crea/actualiza registro de cliente en Notion
6. Registra pago en base de datos de Notion
7. **🆕 Crea evento de calendario automáticamente**
8. Actualiza total pagado del cliente

## 🆕 Funcionalidades Nuevas

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
- 🗑️ Eliminación de variables (con confirmación)
- 📱 Compatible con macOS y Linux

## 🚀 Deployment Automático con GitHub Actions

### 1. Configuración Inicial
```bash
# Configurar token de Fly.io en GitHub
# Ve a: Settings → Secrets and variables → Actions
# Agrega: FLY_API_TOKEN = tu_token_de_flyio
```

### 2. Flujo de Deployment
```bash
# Para staging
git checkout develop
git add .
git commit -m "feat: nueva funcionalidad"
git push origin develop  # ← Deploy automático a staging

# Para producción
git checkout main
git merge develop
git push origin main     # ← Deploy automático a producción
```

### 3. URLs de las Aplicaciones
- **Staging**: `https://nestjs-stripe-notion-dev.fly.dev`
- **Production**: `https://nestjs-stripe-notion.fly.dev`

## 🏭 Configuración para Producción

### 1. Webhooks de Stripe
1. **Development**: Ve a [Stripe Dashboard → Test Webhooks](https://dashboard.stripe.com/test/webhooks)
   - Endpoint: `https://nestjs-stripe-notion-dev.fly.dev/webhook/stripe`
   - Evento: `