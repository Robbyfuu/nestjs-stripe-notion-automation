# 🚀 Configuración de GitHub Actions

Guía para configurar deployment automático con GitHub Actions y Fly.io.

## 📋 Requisitos Previos

1. **Cuenta de Fly.io** activa
2. **Fly CLI** instalado localmente
3. **Repositorio en GitHub** con el código
4. **Apps creadas** en Fly.io para ambos ambientes

## 🔧 Configuración Inicial

### 1. Crear Apps en Fly.io

```bash
# Crear app para staging
flyctl apps create nestjs-stripe-notion-dev

# Crear app para production
flyctl apps create nestjs-stripe-notion
```

### 2. Obtener Token de Fly.io

```bash
# Generar token de acceso
flyctl auth token

# Copia el token que aparece (empieza con 'fly_')
```

### 3. Configurar Secret en GitHub

1. Ve a tu repositorio en GitHub
2. Navega a: **Settings** → **Secrets and variables** → **Actions**
3. Haz clic en **New repository secret**
4. Configura:
   - **Name**: `FLY_API_TOKEN`
   - **Secret**: Pega el token de Fly.io
5. Haz clic en **Add secret**

## 🌍 Configuración de Ambientes

### 🧪 Staging Environment
- **App Name**: `nestjs-stripe-notion-dev`
- **Branch**: `develop`
- **URL**: `https://nestjs-stripe-notion-dev.fly.dev`
- **Deploy**: Automático en push a `develop`

### 🏭 Production Environment
- **App Name**: `nestjs-stripe-notion`
- **Branch**: `main`
- **URL**: `https://nestjs-stripe-notion.fly.dev`
- **Deploy**: Automático en merge a `main`

## 🔄 Flujo de Deployment

### Para Staging
```bash
git checkout develop
git add .
git commit -m "feat: nueva funcionalidad"
git push origin develop
# ↑ Esto dispara deployment automático a staging
```

### Para Production
```bash
git checkout main
git merge develop
git push origin main
# ↑ Esto dispara deployment automático a producción
```

## 📊 Monitoreo de Deployments

### Ver Status en GitHub
1. Ve a tu repositorio
2. Haz clic en la pestaña **Actions**
3. Verás el historial de deployments

### Ver Logs de Aplicación
```bash
# Staging
pnpm run fly:logs:dev

# Production
pnpm run fly:logs:prod
```

### Verificar Health
```bash
# Staging
curl https://nestjs-stripe-notion-dev.fly.dev/health

# Production
curl https://nestjs-stripe-notion.fly.dev/health
```

## 🛡️ Características de Seguridad

### Auto-rollback
- Si el deployment falla, Fly.io automáticamente hace rollback
- Los health checks deben pasar antes de activar la nueva versión

### Zero-downtime
- Los deployments no interrumpen el servicio
- Las requests se redirigen automáticamente

### Environment Isolation
- Staging y Production están completamente separados
- Diferentes bases de datos y credenciales

## 🔧 Troubleshooting

### Error: "App not found"
```bash
# Verificar que las apps existan
flyctl apps list

# Crear si no existen
flyctl apps create nestjs-stripe-notion-dev
flyctl apps create nestjs-stripe-notion
```

### Error: "Unauthorized"
```bash
# Verificar token
flyctl auth whoami

# Regenerar token si es necesario
flyctl auth token
```

### Error: "Build failed"
1. Revisa los logs en GitHub Actions
2. Verifica que el Dockerfile sea válido
3. Confirma que las dependencias estén correctas

### Error: "Health check failed"
1. Verifica que `/health` endpoint funcione
2. Confirma que la aplicación inicie correctamente
3. Revisa las variables de entorno

## 📝 Configuración del Workflow

El archivo `.github/workflows/deploy.yml` está configurado para:

1. **Detectar el branch** (develop o main)
2. **Seleccionar el ambiente** correspondiente
3. **Usar la configuración** correcta (fly.dev.toml o fly.toml)
4. **Deployar automáticamente** con el token de GitHub Secrets

### Estructura del Workflow
```yaml
on:
  push:
    branches:
      - main        # Production
      - develop     # Staging

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
      - name: Setup Fly.io CLI
      - name: Determine environment
      - name: Deploy to environment
```

## 🎯 Próximos Pasos

1. **Configura webhooks** de Stripe para cada ambiente
2. **Crea bases de datos** de Notion separadas
3. **Configura credenciales** en 1Password
4. **Haz tu primer deployment** con push a develop

¡Tu pipeline de CI/CD está listo! 🚀 