# NestJS Stripe Notion Automation

Sistema de automatización que conecta pagos de Stripe con bases de datos de Notion.

## ⚡ Inicio Rápido

### 1. Configuración Inicial
```bash
# Instalar dependencias
pnpm install

# Configurar credenciales de TEST en 1Password
pnpm run setup

# Configurar credenciales de PRODUCCIÓN en 1Password
pnpm run setup:prod
```

### 2. Desarrollo
```bash
# Desarrollo completo (Docker + Stripe webhooks)
pnpm run dev

# Solo aplicación en Docker
pnpm run docker:dev
```

### 3. Producción
```bash
# Configuración completa para producción local
pnpm run prod

# Deployment en Fly.io (recomendado)
pnpm run deploy

# Solo Docker en producción (manual)
pnpm run docker:prod
```

## 🔧 Comandos Principales

| Comando | Descripción |
|---------|-------------|
| `pnpm run setup` | Configurar credenciales de **TEST** en 1Password |
| `pnpm run setup:prod` | Configurar credenciales de **PRODUCCIÓN** en 1Password |
| `pnpm run dev` | Desarrollo completo con webhooks |
| `pnpm run prod` | **Producción local con verificaciones** |
| `pnpm run deploy` | **🚀 Deployment en Fly.io** |
| `pnpm run fly:logs` | Ver logs de Fly.io |
| `pnpm run fly:status` | Estado de la app en Fly.io |
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

## 📋 Requisitos

- **1Password CLI** para gestión de secrets
- **Stripe CLI** para webhooks de desarrollo
- **Docker** para contenedores
- **Credenciales:**
  - Stripe API Key + Webhook Secret
  - Notion Integration Token + Database IDs

## 🔑 Variables de Entorno

Gestionadas automáticamente por 1Password **separadas por ambiente**:

### 🧪 TEST (Desarrollo)
- `STRIPE_SECRET_KEY` → `NestJS Stripe API`
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook`

### 🏭 PRODUCCIÓN
- `STRIPE_SECRET_KEY` → `NestJS Stripe API PROD` 
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook PROD`

### 📚 COMPARTIDO (Ambos ambientes)
- `NOTION_SECRET` → `NestJS Notion Integration`
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases`

## 📝 Flujo de Trabajo

1. Cliente realiza pago en Stripe
2. Stripe envía webhook a `/webhook/stripe`
3. Sistema verifica firma del webhook
4. Extrae datos del cliente y pago
5. Crea/actualiza registro de cliente en Notion
6. Registra pago en base de datos de Notion
7. Actualiza total pagado del cliente

## 🏭 Configuración para Producción

### 1. Webhook de Stripe
1. Ve a [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Crea endpoint: `https://tu-dominio.com/webhook/stripe`
3. Selecciona evento: `payment_intent.succeeded`
4. Copia el signing secret
5. Actualiza en 1Password:
   ```bash
   op item edit "NestJS Stripe Webhook" "Webhook Secret[password]"="whsec_nuevo_secret"
   ```

### 2. Variables de Entorno
- Usa claves **reales** de Stripe (no test keys)
- Configura webhook secret **real** (no de desarrollo local)
- Verifica acceso a bases de datos de Notion

### 3. Despliegue
```bash
# Configuración y verificación automática
pnpm run prod

# Verificar salud
curl https://tu-dominio.com/health

# Ver logs
docker-compose logs -f nestjs-stripe
```

### 4. Seguridad
- ✅ Headers de seguridad configurados
- ✅ Usuario no-root en Docker
- ✅ Verificación de firmas de webhook
- ✅ Logs optimizados para producción
- ✅ Health checks automáticos

## ☁️ Deployment en Fly.io (Recomendado)

### 1. Instalación y Setup
```bash
# Instalar Fly CLI
brew install flyctl
# o
curl -L https://fly.io/install.sh | sh

# Crear cuenta y login
flyctl auth signup
flyctl auth login
```

### 2. Deployment
```bash
# Deployment completo automático
pnpm run deploy

# Con nombre personalizado
./scripts/deploy-flyio.sh mi-app-custom
```

### 3. Configuración de Webhook
1. Después del deployment, ve a [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Agrega endpoint: `https://tu-app.fly.dev/webhook/stripe`
3. Selecciona evento: `payment_intent.succeeded`
4. Copia el signing secret
5. Actualiza en 1Password:
   ```bash
   op item edit "NestJS Stripe Webhook" "Webhook Secret[password]"="whsec_nuevo_secret"
   ```
6. Redespliega:
   ```bash
   flyctl deploy --app tu-app
   ```

### 4. Monitoreo y Gestión
```bash
# Ver logs en tiempo real
pnpm run fly:logs

# Estado de la aplicación
pnpm run fly:status

# Escalar aplicación
flyctl scale count 1 --app tu-app

# Acceso SSH
flyctl ssh console --app tu-app
```

### 5. Características de Fly.io
- ✅ Auto-scaling (se duerme sin tráfico)
- ✅ Health checks automáticos
- ✅ SSL/HTTPS automático
- ✅ CDN global
- ✅ Despliegue desde Git
- ✅ Rollback automático en errores

## 📚 Documentación

- 📖 **[Guía de Desarrollo](DEVELOPMENT.md)** - Workflow con branches y convenciones
- 🏗️ **[Arquitectura del Sistema](docs/ARCHITECTURE.md)** - Diagramas y documentación técnica
- 🔧 **Comandos principales** - Ver tabla abajo

---

**Desarrollado con NestJS + Stripe + Notion + 1Password + Docker + Fly.io**