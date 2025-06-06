# 🔐 Gestión de Variables de Entorno con 1Password

Este proyecto usa **1Password CLI** para manejar todas las variables de entorno de forma segura y centralizada.

## 🚀 Uso Rápido

### **Desarrollo Local**
```bash
# Cargar variables para desarrollo
source scripts/load-env-from-1password.sh development

# Cargar variables para test
source scripts/load-env-from-1password.sh test

# Cargar variables para producción  
source scripts/load-env-from-1password.sh production

# Ejecutar la aplicación
npm run start:dev
```

### **Railway Autodeploys (Automático)**
```bash
# Railway ejecuta automáticamente:
npm run build:railway

# El script instala 1Password CLI y carga variables según RAILWAY_ENVIRONMENT
```

### **Scripts de Mantenimiento**
```bash
# Debug de Railway con variables cargadas
source scripts/load-env-from-1password.sh test
./scripts/railway-debug.sh
```

## 🚂 **Configuración Railway + 1Password**

### **En Railway Dashboard:**
```
1. Service Settings → Variables
2. Añadir: OP_SERVICE_ACCOUNT_TOKEN = [tu_service_account_token]
3. Railway autodeploys cargará automáticamente variables desde 1Password
```

### **Variables automáticas por ambiente:**
- **test branch** → Variables TEST de 1Password
- **main branch** → Variables PROD de 1Password

## 🏗️ Estructura en 1Password

### **Vault: `Programing`**

#### **Items de Autenticación:**
- `Railway Deploy` → `Token`, `Project ID`

#### **Items de Stripe:**
- `NestJS Stripe API PROD` → `Secret Key`
- `NestJS Stripe API TEST` → `Secret Key`
- `NestJS Stripe Webhook PROD` → `Webhook Secret`
- `NestJS Stripe Webhook TEST` → `Webhook Secret`

#### **Items de Notion:**
- `NestJS Notion Integration` → `Secret`
- `NestJS Notion Databases PROD` → `Clients Database ID`, `Payments Database ID`, `Calendar Database ID`
- `NestJS Notion Databases TEST` → `Clients Database ID`, `Payments Database ID`, `Calendar Database ID`

#### **Items de WhatsApp:**
- `NestJS WhatsApp Twilio` → `Account SID`, `Auth Token`, `WhatsApp From`
- `NestJS WhatsApp Meta` → `Use Meta API`

## 🔧 Configuración Inicial

### **1. Instalar 1Password CLI**
```bash
# macOS
brew install --cask 1password/tap/1password-cli

# Linux/Windows - Ver: https://developer.1password.com/docs/cli/get-started/
```

### **2. Autenticarse**
```bash
# Método 1: Service Account (GitHub Actions)
export OP_SERVICE_ACCOUNT_TOKEN="your_service_account_token"

# Método 2: Sesión interactiva (desarrollo local)
op signin
```

### **3. Verificar acceso**
```bash
op read "op://Programing/Railway Deploy/Token"
```

## 🚀 Ventajas de esta Arquitectura

### ✅ **Seguridad**
- ❌ No más secrets hardcodeados en archivos
- ✅ Centralización completa en 1Password
- ✅ Auditoría y control de acceso

### ✅ **Simplicidad**
- ❌ No más archivos `.env` que mantener
- ✅ Un solo script para cargar todo
- ✅ Mismo proceso en desarrollo, CI/CD y Railway

### ✅ **Mantenibilidad**
- ✅ Cambios de secrets solo en 1Password
- ✅ No hay sincronización manual
- ✅ Rotación de tokens simplificada

## 🛠️ Troubleshooting

### **Error: "command not found: op"**
```bash
# Instalar 1Password CLI
brew install --cask 1password/tap/1password-cli
```

### **Error: "401 Unauthorized"**
```bash
# Verificar autenticación
op whoami

# Re-autenticarse si es necesario
op signin
```

### **Error: "item not found"**
```bash
# Verificar que el item existe en 1Password
op item list --vault Programing
```

### **Railway: Variables no cargadas**
```bash
# Verificar OP_SERVICE_ACCOUNT_TOKEN en Railway Dashboard
# Service Settings → Variables → OP_SERVICE_ACCOUNT_TOKEN
```

## 📚 Referencias

- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [1Password GitHub Actions](https://developer.1password.com/docs/ci-cd/github-actions/)
- [Secret References](https://developer.1password.com/docs/cli/secret-references/)
- [Railway Autodeploys](https://docs.railway.com/guides/github-autodeploys) 