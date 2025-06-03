# 🚀 NestJS + Stripe + Notion + WhatsApp Integration

Sistema automatizado de procesamiento de pagos con integración completa de Stripe, Notion y WhatsApp, construido con NestJS y desplegado en Railway.

## ⚡ Inicio Rápido

### **Desarrollo Local (Nativo)**
```bash
# 1. Configurar variables desde 1Password
export OP_SERVICE_ACCOUNT_TOKEN=ops_...

# 2. Iniciar desarrollo
pnpm run dev
```

### **Desarrollo Local (Docker)**
```bash
# 1. Configurar variables desde 1Password  
export OP_SERVICE_ACCOUNT_TOKEN=ops_...

# 2. Iniciar con Docker (ambiente idéntico a producción)
pnpm run dev:docker
```

## 🛠️ Comandos Principales

### **Desarrollo Nativo**
```bash
pnpm run dev              # Desarrollo con hot reload
pnpm run build            # Build para producción
pnpm run start:prod       # Ejecutar build en producción
pnpm run test             # Ejecutar tests
```

### **Desarrollo Docker**
```bash
pnpm run dev:docker       # Iniciar container desarrollo
pnpm run dev:docker:logs  # Ver logs en tiempo real
pnpm run dev:docker:shell # Abrir shell en container
pnpm run dev:docker:test  # Ejecutar tests en container
pnpm run dev:docker:down  # Detener container
```

### **Configuración 1Password**
```bash
pnpm run setup:1password  # Script interactivo para configurar todas las variables
```

## 🏗️ Arquitectura

### **Stack Tecnológico**
- **Backend:** NestJS + TypeScript
- **Pagos:** Stripe API
- **Base de Datos:** Notion API (como base de datos)
- **WhatsApp:** Twilio API
- **Contenedores:** Docker multi-stage
- **Deploy:** Railway con autodeploys
- **Secrets:** 1Password integration

### **Estructura Simplificada**
```
📦 nestjs-stripe/
├── 🐳 Dockerfile              # Multi-stage: dev, build, prod
├── 🐳 docker-compose.yml      # Desarrollo con Docker
├── ⚙️ railway.json            # Configuración Railway
├── 🔐 scripts/
│   ├── dev-docker.sh          # Wrapper desarrollo Docker
│   ├── docker-entrypoint.sh   # Runtime 1Password integration
│   ├── railway-1password-build.sh  # Build 1Password integration
│   └── load-env-from-1password.sh  # Variables locales
├── 📚 docs/                   # Documentación detallada
├── 🔧 src/                    # Código fuente NestJS
└── 📖 README-*.md             # Guías específicas
```

## 🔐 Gestión de Variables

**Todo se maneja con 1Password** - no más archivos `.env`:

### **Desarrollo Local**
```bash
# Cargar variables automáticamente
pnpm run dev              # Con variables de 1Password
# O manual:
source scripts/load-env-from-1password.sh development
```

### **Railway Production**
- Variables se cargan automáticamente desde 1Password
- Solo necesitas configurar `OP_SERVICE_ACCOUNT_TOKEN` en Railway Dashboard

## 🚂 Deployment

### **Railway Autodeploys**
```bash
# Push automático detecta cambios
git push origin test      # Deploy a ambiente TEST
git push origin main      # Deploy a ambiente PRODUCTION
```

### **Variables de Railway**
- `OP_SERVICE_ACCOUNT_TOKEN`: Tu Service Account de 1Password
- Todas las demás variables se cargan automáticamente

## 📖 Documentación

- **[🔐 1Password Setup](README-1PASSWORD.md)** - Gestión de secrets
- **[🚂 Railway Setup](RAILWAY-SETUP.md)** - Configuración de deploy
- **[📚 Docs detallados](docs/)** - Arquitectura, Notion, etc.

## 🎯 Features

### **Integración Stripe**
- ✅ Procesamiento de pagos
- ✅ Webhooks automáticos
- ✅ Manejo de suscripciones

### **Integración Notion**
- ✅ Base de datos de clientes
- ✅ Registro de pagos
- ✅ Calendar de eventos

### **Integración WhatsApp**
- ✅ Notificaciones de pago
- ✅ Confirmaciones automáticas
- ✅ Soporte Twilio + Meta APIs

### **DevOps**
- ✅ Docker multi-stage optimizado
- ✅ Railway autodeploys
- ✅ 1Password secrets management
- ✅ Ambiente dev = ambiente prod

## 🚀 Próximos Pasos

1. **Setup 1Password**: [Guía](README-1PASSWORD.md)
2. **Deploy Railway**: [Guía](RAILWAY-SETUP.md)
3. **Desarrollo**: `pnpm run dev` o `pnpm run dev:docker`

---

**📧 Soporte:** Ver documentación en `/docs` o crear issue en GitHub