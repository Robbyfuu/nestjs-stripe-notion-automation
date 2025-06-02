# 🚂 Railway Deployment Guide

Esta guía explica cómo configurar y desplegar la aplicación NestJS + Stripe + Notion + WhatsApp en Railway con CI/CD automático.

## 🎯 Arquitectura de Deployment

### Entornos configurados:
- **🔧 Develop**: Desarrollo local (sin deploy, usa `pnpm run dev:local`)
- **🧪 Test**: `nestjs-stripe-notion-test` (rama `test`)
- **🏭 Production**: `nestjs-stripe-notion-prod` (rama `main`)

### Flujo de trabajo:
```
develop (local) → test (deploy) → main (deploy)
```

## 🛠️ Setup Inicial

### 1. Instalar Railway CLI

```bash
npm install -g @railway/cli
```

### 2. Configurar proyecto en Railway

1. Ve a [Railway.app](https://railway.app)
2. Conecta tu GitHub
3. Crea un nuevo proyecto desde el repositorio

### 3. Crear servicios

Crear **2 servicios** (develop es solo local):
- `nestjs-stripe-notion-test` (Test)
- `nestjs-stripe-notion-prod` (Production)

### 4. Configurar variables automáticamente

```bash
# Configurar ambos entornos automáticamente
pnpm run setup:railway
```

## 🔧 Variables de Entorno

### 🧪 Test (rama test)
Usa variables de **1password-test.env**:

```
STRIPE_SECRET_KEY=sk_test_... (TEST)
STRIPE_WEBHOOK_SECRET=whsec_test_...
NOTION_CLIENTS_DATABASE_ID=test_clients_db_id
NOTION_PAYMENTS_DATABASE_ID=test_payments_db_id
NOTION_CALENDAR_DATABASE_ID=test_calendar_db_id
```

### 🏭 Production (rama main)
Usa variables de **1password-prod.env**:

```
STRIPE_SECRET_KEY=sk_live_... (LIVE)
STRIPE_WEBHOOK_SECRET=whsec_prod_...
NOTION_CLIENTS_DATABASE_ID=prod_clients_db_id
NOTION_PAYMENTS_DATABASE_ID=prod_payments_db_id
NOTION_CALENDAR_DATABASE_ID=prod_calendar_db_id
```

### 📚 Variables compartidas
```
NOTION_SECRET=ntn_...
TWILIO_ACCOUNT_SID=ACxxxxxxxxx
TWILIO_AUTH_TOKEN=xxx
TWILIO_WHATSAPP_FROM=+14155238886
USE_META_WHATSAPP_API=false
```

## 🚀 CI/CD con GitHub Actions

### Setup de GitHub Secrets

1. Ve a GitHub > Settings > Secrets and variables > Actions
2. Añade: `RAILWAY_TOKEN=tu_railway_token_aquí`

### Flujo automático:

1. **Push a `test`** → Deploy automático a Test
2. **Push a `main`** → Deploy automático a Production
3. **`develop`** → Solo desarrollo local (no deploy)

## 🔧 Comandos útiles

### Desarrollo local
```bash
# Desarrollo local sin Docker
pnpm run dev:local

# Desarrollo con Docker
pnpm run docker:dev
```

### Railway CLI
```bash
# Ver servicios
pnpm run railway:status

# Ver logs por entorno
pnpm run railway:logs:test
pnpm run railway:logs:prod

# Deploy manual (opcional)
pnpm run railway:deploy:test
pnpm run railway:deploy:prod

# Configurar variables manualmente
railway variables set STRIPE_SECRET_KEY=sk_test_... --service nestjs-stripe-notion-test
```

### Testing endpoints
```bash
# Test environment
curl https://nestjs-stripe-notion-test.railway.app/health

curl -X POST https://nestjs-stripe-notion-test.railway.app/whatsapp/send \
  -H "Content-Type: application/json" \
  -d '{"to": "+56996419674", "body": "Test desde Railway TEST!"}'

# Production environment
curl https://nestjs-stripe-notion-prod.railway.app/health
```

## 📊 URLs de servicios

- **🔧 Develop**: `http://localhost:3000` (local)
- **🧪 Test**: `https://nestjs-stripe-notion-test.railway.app`
- **🏭 Production**: `https://nestjs-stripe-notion-prod.railway.app`

### Endpoints importantes:
- `/health` - Health check
- `/whatsapp/status` - Estado de WhatsApp
- `/whatsapp/send` - Envío de mensajes
- `/stripe/webhook` - Webhook de Stripe

## 🛡️ Seguridad

### Variables sensibles:
✅ Todas las variables están configuradas en Railway (no en código)
✅ Diferentes claves para TEST y PROD
✅ Webhook secrets únicos por entorno
✅ Bases de datos separadas por entorno

### Acceso:
- Solo colaboradores del repo pueden hacer deploy
- Variables de entorno encriptadas en Railway
- HTTPS automático en todas las URLs

## 🔄 Flujo Git + Railway

### Arquitectura de 3 Entornos
```
develop (local) → test (Railway TEST) → main (Railway PROD)
```

### ✅ Flujo Seguro Recomendado

#### 1. **Desarrollo** (rama `develop`)
```bash
git checkout develop
# ... desarrollo local ...
git add . && git commit -m "feat: nueva funcionalidad"
git push origin develop
```

#### 2. **Testing** (rama `test` → Railway TEST)
```bash
git checkout test
git merge develop                    # Merge desde develop
git push origin test                 # → 🚀 Deploy automático Railway TEST
```

#### 3. **Validación** 
```bash
# Probar en ambiente TEST
curl https://nestjs-stripe-notion-test.railway.app/health
curl https://nestjs-stripe-notion-test.railway.app/whatsapp/status

# Validar webhooks, variables, etc.
```

#### 4. **Producción** (rama `main` → Railway PROD)
```bash
# ⚠️ SOLO si TEST pasa todas las validaciones
git checkout main
git merge test                       # ✅ Merge desde TEST (no desde develop)
git push origin main                 # → 🚀 Deploy automático Railway PROD
```

### 🚨 **Reglas importantes:**
- ❌ **NUNCA** merge directo `develop` → `main`
- ✅ **SIEMPRE** merge `develop` → `test` → `main`
- ✅ **VALIDAR** en TEST antes de ir a PROD
- ✅ **REVISAR** logs de Railway después de cada deploy

## 🐛 Troubleshooting

### Ver logs por entorno:
```bash
# Test
pnpm run railway:logs:test

# Production
pnpm run railway:logs:prod
```

### Reiniciar servicios:
```bash
# Test
railway redeploy --service nestjs-stripe-notion-test

# Production
railway redeploy --service nestjs-stripe-notion-prod
```

### Verificar variables:
```bash
# Test
railway variables --service nestjs-stripe-notion-test

# Production
railway variables --service nestjs-stripe-notion-prod
```

## 🚀 Configuración de Webhooks

### Stripe webhooks para cada entorno:

#### Test
1. Ve a [Stripe Dashboard → Test Webhooks](https://dashboard.stripe.com/test/webhooks)
2. Crea webhook: `https://nestjs-stripe-notion-test.railway.app/webhook/stripe`
3. Evento: `payment_intent.succeeded`

#### Production
1. Ve a [Stripe Dashboard → Live Webhooks](https://dashboard.stripe.com/webhooks)
2. Crea webhook: `https://nestjs-stripe-notion-prod.railway.app/webhook/stripe`
3. Evento: `payment_intent.succeeded`

## 📈 Características de Railway

- ✅ Setup extremadamente fácil
- ✅ Variables de entorno integradas
- ✅ Deploy automático desde GitHub
- ✅ Logs en tiempo real
- ✅ HTTPS automático
- ✅ Escalado automático
- ✅ Health checks integrados

---

¡Tu aplicación NestJS está lista para Railway con CI/CD automático! 🎉 