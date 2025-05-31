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
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases`

### 🏭 PRODUCCIÓN
- `STRIPE_SECRET_KEY` → `NestJS Stripe API PROD` 
- `STRIPE_WEBHOOK_SECRET` → `NestJS Stripe Webhook PROD`
- `NOTION_PAYMENTS_DATABASE_ID` → `NestJS Notion Databases PROD`
- `NOTION_CLIENTS_DATABASE_ID` → `NestJS Notion Databases PROD`

### 📚 COMPARTIDO (Ambos ambientes)
- `NOTION_SECRET` → `NestJS Notion Integration`

## 📝 Flujo de Trabajo

1. Cliente realiza pago en Stripe
2. Stripe envía webhook a `/webhook/stripe`
3. Sistema verifica firma del webhook
4. Extrae datos del cliente y pago
5. Crea/actualiza registro de cliente en Notion
6. Registra pago en base de datos de Notion
7. Actualiza total pagado del cliente

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
   - Evento: `payment_intent.succeeded`

2. **Production**: Ve a [Stripe Dashboard → Live Webhooks](https://dashboard.stripe.com/webhooks)
   - Endpoint: `https://nestjs-stripe-notion.fly.dev/webhook/stripe`
   - Evento: `payment_intent.succeeded`

### 2. Bases de Datos de Notion
Crea **4 bases de datos separadas**:
- `Clientes DEV` + `Pagos DEV` (para staging)
- `Clientes PROD` + `Pagos PROD` (para producción)

### 3. Verificación de Health
```bash
# Staging
curl https://nestjs-stripe-notion-dev.fly.dev/health

# Production
curl https://nestjs-stripe-notion.fly.dev/health
```

### 4. Seguridad
- ✅ Headers de seguridad configurados
- ✅ Usuario no-root en Docker
- ✅ Verificación de firmas de webhook
- ✅ Logs optimizados para producción
- ✅ Health checks automáticos
- ✅ Auto-rollback en errores

## ☁️ Características de Fly.io

### 🎯 Auto-scaling
- **Development**: Se duerme sin tráfico (ahorro de costos)
- **Production**: Escalado automático según demanda

### 🔄 Deployment Features
- ✅ Deploy automático desde GitHub
- ✅ Rollback automático en errores
- ✅ Health checks antes de activar
- ✅ Zero-downtime deployments
- ✅ SSL/HTTPS automático

### 📊 Monitoreo
```bash
# Logs en tiempo real
pnpm run fly:logs:dev    # Staging
pnpm run fly:logs:prod   # Production

# Estado de aplicaciones
pnpm run fly:status:dev  # Staging
pnpm run fly:status:prod # Production
```

## 🔧 Troubleshooting

### Problemas con Webhooks de Stripe
- **Error 500**: Verifica que el webhook secret sea correcto en 1Password
- **Firma inválida**: Confirma que la URL del webhook esté configurada correctamente
- **No recibe eventos**: Revisa que `payment_intent.succeeded` esté seleccionado

### Problemas con 1Password
- **CLI no encontrado**: Instala con `brew install --cask 1password/tap/1password-cli`
- **No autenticado**: Ejecuta `eval $(op signin)` 
- **Credenciales no encontradas**: Verifica nombres exactos de las entradas

### Problemas con GitHub Actions
- **Deploy falla**: Verifica que `FLY_API_TOKEN` esté configurado en GitHub Secrets
- **App no existe**: Crea las apps con `flyctl apps create nestjs-stripe-notion` y `nestjs-stripe-notion-dev`
- **Permisos**: Confirma que el token tenga permisos de deploy

### Problemas con Fly.io
- **App no responde**: Revisa logs con `pnpm run fly:logs:dev` o `pnpm run fly:logs:prod`
- **Health check falla**: Confirma que `/health` devuelva 200
- **Variables no cargadas**: Verifica que 1Password CLI esté funcionando en el container

### Problemas con Docker
- **Error de permisos**: Asegúrate de que Docker esté corriendo
- **Variables no cargadas**: Verifica que 1Password CLI esté funcionando
- **Puerto ocupado**: Usa `docker-compose down` para limpiar

## 📚 Documentación

- 📖 **[Guía de Desarrollo](DEVELOPMENT.md)** - Workflow con branches y convenciones
- 🏗️ **[Documentación Técnica](docs/)** - Arquitectura y diagramas del sistema

---

**Desarrollado con NestJS + Stripe + Notion + 1Password + Docker + Fly.io + GitHub Actions**