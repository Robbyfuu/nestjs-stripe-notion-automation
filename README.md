# 🌐 NestJS + Stripe + Notion + WhatsApp

API de NestJS con integración completa de **Stripe**, **Notion** y **WhatsApp** usando Twilio. Incluye webhooks de Stripe que automáticamente crean clientes en Notion y envían notificaciones por WhatsApp.

## 🚀 Stack Tecnológico

- **Backend**: NestJS + TypeScript
- **Pagos**: Stripe (webhooks)
- **Base de Datos**: Notion (como DB)
- **Comunicación**: WhatsApp (Twilio)
- **Seguridad**: 1Password para secretos
- **Deployment**: Railway + GitHub Actions
- **Containerización**: Docker multi-entorno

## 📱 Funcionalidades

### 🔗 Integración WhatsApp
- ✅ Envío de mensajes por Twilio
- ✅ Sandbox verificado (+14155238886)
- ✅ Tu número verificado: `+56996419674`
- ✅ Endpoints REST para envío

### 💳 Webhooks de Stripe
- ✅ Escucha `payment_intent.succeeded`
- ✅ Crea clientes automáticamente en Notion
- ✅ Envía notificación por WhatsApp
- ✅ Diferentes entornos (TEST/PROD)

### 📊 Base de Datos Notion
- ✅ **Clientes**: Información de clientes
- ✅ **Pagos**: Registro de transacciones
- ✅ **Calendario**: Eventos y citas
- ✅ Diferentes bases por entorno

## 🏗️ Arquitectura

### 🎯 Entornos

- **🔧 Develop**: Desarrollo local (`localhost:3000`)
- **🧪 Test**: Deploy automático Railway (`test` branch)
- **🏭 Production**: Deploy automático Railway (`main` branch)

### 🔄 Flujo de trabajo

```
develop (local) → test (deploy & test) → main (prod)
```

**Proceso seguro:**
1. **Desarrollo**: Trabajar en `develop`
2. **Testing**: Merge a `test` → Deploy automático Railway TEST
3. **Validación**: Probar en ambiente TEST
4. **Producción**: Merge `test` → `main` → Deploy automático Railway PROD

## 🛠️ Desarrollo Local

### 1. Clonar repositorio
```bash
git clone <repo-url>
cd nestjs-stripe
pnpm install
```

### 2. Configurar 1Password
```bash
# Configurar variables de desarrollo automáticamente
pnpm run setup:dev

# O configurar variables de producción
pnpm run setup:prod
```

### 3. Ejecutar localmente
```bash
# Desarrollo rápido (recomendado)
pnpm run dev:local

# O con Docker (desarrollo)
pnpm run docker:dev
```

### 4. Verificar funcionamiento
```bash
curl http://localhost:3000/health
```

## 🔧 Scripts disponibles

### Desarrollo
```bash
pnpm run dev:local        # Desarrollo local directo
pnpm run setup:dev        # Setup 1Password dev
pnpm run setup:prod       # Setup 1Password prod
```

### Docker multi-entorno
```bash
pnpm run docker:dev       # Puerto 3000 (desarrollo)
pnpm run docker:test      # Puerto 3001 (testing)
pnpm run docker:prod      # Puerto 3002 (producción)
pnpm run docker:down      # Detener contenedores
```

### Railway (deployment)
```bash
pnpm run setup:railway    # Configurar Railway
pnpm run railway:logs:test # Ver logs test
pnpm run railway:logs:prod # Ver logs prod
```

## 📱 Endpoints WhatsApp

### Enviar mensaje
```bash
curl -X POST http://localhost:3000/whatsapp/send \
  -H "Content-Type: application/json" \
  -d '{
    "to": "+56996419674",
    "body": "¡Hola desde NestJS!"
  }'
```

### Verificar estado
```bash
curl http://localhost:3000/whatsapp/status
```

## 💳 Testing Stripe

### Webhook local (para testing)
```bash
# Con stripe CLI
stripe listen --forward-to localhost:3000/webhook/stripe

# Test webhook
stripe trigger payment_intent.succeeded
```

## 📊 Health Checks

### Local
```bash
curl http://localhost:3000/health
```

### Docker
```bash
curl http://localhost:3000/health   # dev
curl http://localhost:3001/health   # test  
curl http://localhost:3002/health   # prod
```

### Railway (deployment)
```bash
curl https://nestjs-stripe-notion-automation-test.up.railway.app/health   # test
curl https://nestjs-stripe-notion-automation-prod.up.railway.app/health   # prod
```

## 🔒 Variables de Entorno

### Estructura 1Password
```
📁 1password-dev.env     → Desarrollo local
📁 1password-test.env    → Testing Railway 
📁 1password-prod.env    → Production Railway
```

### Variables principales
```bash
STRIPE_SECRET_KEY=sk_test_... (dev/test) | sk_live_... (prod)
STRIPE_WEBHOOK_SECRET=whsec_...
NOTION_SECRET=ntn_...
NOTION_CLIENTS_DATABASE_ID=...
NOTION_PAYMENTS_DATABASE_ID=...
TWILIO_ACCOUNT_SID=ACxxxxxxxxx
TWILIO_AUTH_TOKEN=xxx
TWILIO_WHATSAPP_FROM=+14155238886
```

## 🚂 Railway Deployment

### 🚂 Railway Commands
```bash
# Setup automático completo (recomendado)
pnpm run railway:auto

# Upload manual de variables vía API
pnpm run railway:upload  

# Debug Railway API
pnpm run railway:debug

# Logs y estado
pnpm run railway:logs:test
pnpm run railway:logs:prod
pnpm run railway:status
```

### CI/CD automático
- **Push a `develop`** → Solo desarrollo local
- **Push a `test`** → Deploy automático a Railway TEST  
- **Merge `test` → `main`** → Deploy automático a Railway PROD

**Flujo recomendado:**
```bash
# 1. Desarrollo
git checkout develop
git add . && git commit -m "feat: nueva feature"
git push origin develop

# 2. Testing  
git checkout test
git merge develop
git push origin test  # → Deploy Railway TEST

# 3. Validar en TEST
curl https://nestjs-stripe-notion-automation-test.up.railway.app/health

# 4. Producción (solo si TEST pasa)
git checkout main  
git merge test
git push origin main  # → Deploy Railway PROD
```

### URLs Railway
- **Test**: `https://nestjs-stripe-notion-automation-test.up.railway.app`
- **Production**: `https://nestjs-stripe-notion-automation-prod.up.railway.app`

Ver guía completa: [README-RAILWAY.md](./README-RAILWAY.md)

## 🐛 Troubleshooting

### Verificar Docker
```bash
docker ps
docker-compose logs nestjs-dev
```

### Verificar 1Password
```bash
op account list
op item list
```

### Verificar Railway
```bash
pnpm run railway:status
pnpm run railway:logs:test
```

## 📝 Notas importantes

1. **WhatsApp**: Solo funciona con números verificados en Twilio
2. **Stripe**: Usa claves TEST en desarrollo, LIVE en producción
3. **Notion**: Bases de datos separadas por entorno
4. **Railway**: Deploy automático solo en `test` y `main`
5. **Git Flow**: SIEMPRE merge a `main` desde `test` (nunca desde `develop`)

---

¡API lista para producción con Railway + CI/CD! 🎉