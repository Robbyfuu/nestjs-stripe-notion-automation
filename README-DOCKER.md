# 🐳 NestJS Stripe Notion WhatsApp - Docker Setup

## 📋 **Resumen**

Esta aplicación NestJS está completamente dockerizada con soporte para 3 ambientes:
- **DEV**: Desarrollo local
- **TEST**: Testing en Fly.io 
- **PROD**: Producción en Fly.io

## 🚀 **Inicio Rápido**

### 1. **Configurar 1Password** 
```bash
# Ejecutar configuración interactiva
pnpm run setup:interactive

# O configurar manualmente cada variable
./scripts/setup-1password-simple.sh
```

### 2. **Ejecutar con Docker**
```bash
# Desarrollo (puerto 3000)
pnpm run dev

# Testing (puerto 3001) 
pnpm run test:env

# Producción (puerto 3002)
pnpm run prod
```

## 🏗️ **Arquitectura de Ambientes**

### **Variables Compartidas**
- **WhatsApp**: Todas las configuraciones (Twilio + Meta API)
- **Notion Integration**: Secret de integración

### **Variables por Ambiente**

| Servicio | DEV | TEST | PROD |
|----------|-----|------|------|
| **Stripe API** | `sk_test_` | `sk_test_` | `sk_live_` |
| **Stripe Webhook** | DEV endpoint | TEST endpoint | PROD endpoint |
| **Notion DBs** | Dev databases | Dev databases | Prod databases |

## 📦 **Comandos Docker**

### **Desarrollo**
```bash
# Iniciar contenedor de desarrollo
pnpm run docker:dev

# Forzar rebuild
pnpm run docker:dev:build

# Ver logs en tiempo real
pnpm run docker:logs:dev
```

### **Testing** 
```bash
# Iniciar contenedor de testing
pnpm run docker:test

# Forzar rebuild
pnpm run docker:test:build

# Ver logs
pnpm run docker:logs:test
```

### **Producción**
```bash
# Iniciar contenedor de producción
pnpm run docker:prod

# Forzar rebuild  
pnpm run docker:prod:build

# Ver logs
pnpm run docker:logs:prod
```

### **Gestión General**
```bash
# Detener todos los contenedores
pnpm run docker:down

# Ver estado de contenedores
docker ps

# Acceder al contenedor
docker exec -it nestjs-stripe-dev bash
```

## 🔐 **Configuración de 1Password**

### **Estructura de Items en 1Password**

En tu vault "Personal", necesitas estos items:

#### **Stripe**
- `NestJS Stripe API TEST` (Secret Key para DEV + TEST)
- `NestJS Stripe API PROD` (Secret Key para PROD)
- `NestJS Stripe Webhook DEV` (Webhook para desarrollo local)
- `NestJS Stripe Webhook TEST` (Webhook para Fly.io testing)
- `NestJS Stripe Webhook PROD` (Webhook para Fly.io producción)

#### **Notion**
- `NestJS Notion Integration` (Integration Secret)
- `NestJS Notion Databases DEV` (IDs de DBs para DEV + TEST)
- `NestJS Notion Databases PROD` (IDs de DBs para PROD)

#### **WhatsApp**
- `NestJS WhatsApp Twilio` (Account SID, Auth Token, WhatsApp From)
- `NestJS WhatsApp Meta` (Use Meta API, Access Token, Phone Number ID)

### **Configuración Rápida**
```bash
# Solo desarrollo (mínimo para empezar)
./scripts/setup-1password-simple.sh
# Seleccionar opción "c" (configuración rápida desarrollo)

# WhatsApp (recomendado Twilio para empezar)
./scripts/setup-1password-simple.sh  
# Seleccionar opción "w" → opción "1" (solo Twilio)
```

## 🌐 **Puertos de Acceso**

- **DEV**: http://localhost:3000
- **TEST**: http://localhost:3001  
- **PROD**: http://localhost:3002

## 🔧 **Troubleshooting**

### **Error: 1Password no puede cargar variables**
```bash
# Verificar sesión de 1Password
op account list

# Re-autenticar si es necesario
eval $(op signin)
```

### **Error: Variables no encontradas**
```bash
# Verificar que los items existen
op item list | grep "NestJS"

# Ver configuración específica
op item get "NestJS WhatsApp Twilio"
```

### **Problemas de contenedores**
```bash
# Limpiar todo y empezar de nuevo
docker system prune -a
pnpm run docker:dev:build
```

### **Logs detallados**
```bash
# Ver logs de Docker
pnpm run docker:logs:dev

# Entrar al contenedor para debug
docker exec -it nestjs-stripe-dev bash
```

## 📁 **Estructura de Archivos**

```
├── 1password-dev.env      # Variables para desarrollo
├── 1password-test.env     # Variables para testing  
├── 1password-prod.env     # Variables para producción
├── docker-compose.yml     # Configuración de servicios
├── Dockerfile             # Multi-stage build
└── scripts/
    ├── setup-1password-simple.sh  # Configuración interactiva
    └── docker-entrypoint.sh       # Script de entrada
```

## 🚀 **Deploy en Fly.io**

```bash
# Configurar app de testing
fly apps create nestjs-stripe-test

# Configurar app de producción  
fly apps create nestjs-stripe-prod

# Deploy testing
fly deploy --config fly.test.toml

# Deploy producción
fly deploy --config fly.prod.toml
``` 