# 🚀 Guía de Deployment

Guía completa para desplegar la aplicación NestJS Stripe Notion en Fly.io con diferentes ambientes.

## 🌍 Estrategia de Ambientes

Esta aplicación maneja **2 ambientes separados**:

- 🧪 **Development**: `nestjs-stripe-notion-dev` - Para pruebas y desarrollo
- 🏭 **Production**: `nestjs-stripe-notion` - Para datos reales

Cada ambiente tiene:
- ✅ Apps separadas en Fly.io
- ✅ Variables de entorno diferentes
- ✅ Bases de datos de Notion separadas
- ✅ Credenciales de Stripe separadas

## 📋 Prerrequisitos

### 1. Instalar Herramientas

```bash
# Fly.io CLI
brew install flyctl
# O alternativamente:
curl -L https://fly.io/install.sh | sh

# 1Password CLI
brew install --cask 1password/tap/1password-cli
```

### 2. Autenticarse

```bash
# Fly.io
flyctl auth login

# 1Password
op signin
```

### 3. Configurar Variables de Entorno

**Usar el script interactivo (recomendado):**
```bash
pnpm run setup:interactive
```

**O configurar por ambiente:**
```bash
# Solo desarrollo
pnpm run setup:interactive
# Seleccionar opción 'c'

# Solo producción  
pnpm run setup:interactive
# Seleccionar opción 'p'
```

## 🚀 Scripts de Deploy

### Deploy Rápido

```bash
# Desarrollo
pnpm run deploy:dev

# Producción
pnpm run deploy:prod
```

### Deploy con Opciones

```bash
# Con nombre personalizado
./scripts/deploy-flyio.sh dev --app mi-app-dev
./scripts/deploy-flyio.sh prod --app mi-app-prod

# Ver ayuda
pnpm run deploy:help
```

## 🔧 Proceso de Deploy

### 1. **Verificación de Prerrequisitos**
- ✅ Fly CLI instalado y autenticado
- ✅ 1Password CLI instalado y autenticado
- ✅ Variables configuradas en 1Password

### 2. **Validación de Variables**
El script verifica que estén configuradas:

**Para Development:**
- Stripe API Secret Key (dev)
- Stripe Webhook Secret (dev)
- Notion Integration Secret
- Notion Clients Database ID (dev)
- Notion Payments Database ID (dev)
- Notion Calendar Database ID (dev)

**Para Production:**
- Stripe API Secret Key (prod)
- Stripe Webhook Secret (prod)
- Notion Integration Secret
- Notion Clients Database ID (prod)
- Notion Payments Database ID (prod)
- Notion Calendar Database ID (prod)

### 3. **Creación/Actualización de App**
- Si la app no existe, se crea automáticamente
- Se configura usando el archivo `.toml` correspondiente:
  - `fly.dev.toml` para desarrollo
  - `fly.toml` para producción

### 4. **Configuración de Variables**
Se configuran todas las variables como secretos en Fly.io:
```bash
flyctl secrets set \
    NODE_ENV="development/production" \
    STRIPE_SECRET_KEY="sk_..." \
    STRIPE_WEBHOOK_SECRET="whsec_..." \
    NOTION_SECRET="secret_..." \
    NOTION_CLIENTS_DATABASE_ID="..." \
    NOTION_PAYMENTS_DATABASE_ID="..." \
    NOTION_CALENDAR_DATABASE_ID="..." \
    --app app-name
```

### 5. **Deploy de la Aplicación**
```bash
flyctl deploy --config fly.dev.toml --app nestjs-stripe-notion-dev
```

## 📊 Gestión Post-Deploy

### Ver Estado de Apps

```bash
# Development
pnpm run fly:status:dev
flyctl status --app nestjs-stripe-notion-dev

# Production
pnpm run fly:status:prod
flyctl status --app nestjs-stripe-notion
```

### Ver Logs

```bash
# Development
pnpm run fly:logs:dev
flyctl logs --app nestjs-stripe-notion-dev

# Production
pnpm run fly:logs:prod
flyctl logs --app nestjs-stripe-notion
```

### Comandos Útiles

```bash
# Escalar aplicación
flyctl scale count 1 --app nestjs-stripe-notion-dev

# Acceso SSH
flyctl ssh console --app nestjs-stripe-notion-dev

# Ver secretos configurados
flyctl secrets list --app nestjs-stripe-notion-dev

# Actualizar un secreto específico
flyctl secrets set NUEVA_VAR="valor" --app nestjs-stripe-notion-dev
```

## 🔗 URLs de las Aplicaciones

### Development
- **App**: https://nestjs-stripe-notion-dev.fly.dev
- **Health Check**: https://nestjs-stripe-notion-dev.fly.dev/health
- **Stripe Webhook**: https://nestjs-stripe-notion-dev.fly.dev/webhook/stripe

### Production
- **App**: https://nestjs-stripe-notion.fly.dev
- **Health Check**: https://nestjs-stripe-notion.fly.dev/health
- **Stripe Webhook**: https://nestjs-stripe-notion.fly.dev/webhook/stripe

## ⚙️ Configuración de Webhooks Stripe

### Development
Los webhooks de desarrollo usan Stripe CLI localmente.

### Production
1. **Ir a Stripe Dashboard**: https://dashboard.stripe.com/webhooks
2. **Crear nuevo endpoint**:
   ```
   URL: https://nestjs-stripe-notion.fly.dev/webhook/stripe
   Eventos: payment_intent.succeeded
   ```
3. **Copiar el Signing Secret**
4. **Actualizarlo en 1Password**:
   ```bash
   pnpm run setup:interactive
   # Seleccionar opción 4 (Stripe Webhook Secret PROD)
   ```
5. **Redesplegar**:
   ```bash
   pnpm run deploy:prod
   ```

## 🚨 Troubleshooting

### Error: "database_not_found"
```bash
# Verificar que las bases de datos estén configuradas
pnpm run setup:interactive
# Seleccionar opción 'v' para ver valores actuales
```

### Error: "unauthorized" en Notion
```bash
# Verificar token de integración
pnpm run setup:interactive
# Seleccionar opción 5 (Notion Integration Secret)
```

### Error: Variables faltantes
```bash
# El script te dirá exactamente qué falta
pnpm run deploy:dev  # o deploy:prod

# Configurar variables faltantes
pnpm run setup:interactive
```

### Error de build o deploy
```bash
# Ver logs detallados
flyctl logs --app nestjs-stripe-notion-dev

# Verificar status
flyctl status --app nestjs-stripe-notion-dev

# Redesplegar
pnpm run deploy:dev
```

### App no responde
```bash
# Verificar que esté ejecutándose
flyctl status --app nestjs-stripe-notion-dev

# Reiniciar app
flyctl apps restart nestjs-stripe-notion-dev

# Escalar si está en 0
flyctl scale count 1 --app nestjs-stripe-notion-dev
```

## 📝 Flujo de Trabajo Recomendado

### 1. **Primera vez**
```bash
# 1. Configurar todas las variables
pnpm run setup:interactive

# 2. Deploy a desarrollo
pnpm run deploy:dev

# 3. Probar aplicación
curl https://nestjs-stripe-notion-dev.fly.dev/health

# 4. Cuando esté listo, deploy a producción
pnpm run deploy:prod
```

### 2. **Actualizaciones de código**
```bash
# Development
pnpm run deploy:dev

# Production (después de probar en dev)
pnpm run deploy:prod
```

### 3. **Actualizaciones de variables**
```bash
# 1. Actualizar en 1Password
pnpm run setup:interactive

# 2. Redesplegar
pnpm run deploy:dev   # y/o
pnpm run deploy:prod
```

## 🏷️ Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `pnpm run deploy:dev` | Deploy a desarrollo |
| `pnpm run deploy:prod` | Deploy a producción |
| `pnpm run deploy:help` | Ver ayuda de deploy |
| `pnpm run fly:status:dev` | Estado app desarrollo |
| `pnpm run fly:status:prod` | Estado app producción |
| `pnpm run fly:logs:dev` | Logs desarrollo |
| `pnpm run fly:logs:prod` | Logs producción |
| `pnpm run setup:interactive` | Configurar variables |
| `pnpm run setup:help` | Ver todos los scripts | 