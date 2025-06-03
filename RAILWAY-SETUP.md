# 🚂 Railway + 1Password Setup Guide

## 🎯 Configuración Paso a Paso

### **Paso 1: Configurar Service Account en 1Password**

1. Ve a [1Password Business Console](https://my.1password.com/)
2. **Settings** → **Service Accounts** → **Create Service Account**
3. Nombre: `Railway NestJS Deploy`
4. **Vault Access**: Dar acceso al vault `Programing`
5. **Copiar el token** (empieza con `ops_`)

### **Paso 2: Configurar Variable en Railway**

1. Ve a tu proyecto en [Railway Dashboard](https://railway.app/dashboard)
2. Selecciona tu servicio
3. **Settings** → **Variables** → **Add Variable**
4. Añadir:
   ```
   Name: OP_SERVICE_ACCOUNT_TOKEN
   Value: ops_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

### **Paso 3: Redeploy**

1. Railway detectará el cambio automáticamente
2. O hacer push a tu branch para trigger el autodeploy

## 🔍 Verificar que Funciona

En los logs de Railway verás:
```
🔐 Building with 1Password integration...
[RAILWAY-1PASSWORD] 🚂 Railway Build con 1Password - Iniciando...
[RAILWAY-1PASSWORD] 📍 Ambiente detectado: production
[RAILWAY-1PASSWORD] 🔐 OP_SERVICE_ACCOUNT_TOKEN encontrado
[RAILWAY-1PASSWORD] ✅ 1Password CLI disponible
[RAILWAY-1PASSWORD] 📥 Cargando STRIPE_SECRET_KEY...
[RAILWAY-1PASSWORD] ✅ STRIPE_SECRET_KEY cargado
```

## 🛠️ Troubleshooting

### **Build falla con 1Password**
- Verificar que el Service Account tiene acceso al vault `Programing`
- Verificar que todos los items existen en 1Password
- Revisar los logs de build para errores específicos

### **Variables no se cargan**
- El token debe empezar con `ops_`
- El vault debe llamarse exactamente `Programing`
- Los items deben tener los nombres exactos del script

---

## 🆘 Alternativa: Variables Manuales

Si prefieres no usar 1Password, puedes configurar las variables manualmente en Railway:

### **Variables para TEST/PRODUCTION:**
```
STRIPE_SECRET_KEY=sk_test_xxx (o sk_live_xxx para prod)
STRIPE_WEBHOOK_SECRET=whsec_xxx
NOTION_SECRET=secret_xxx
NOTION_CLIENTS_DATABASE_ID=xxx
NOTION_PAYMENTS_DATABASE_ID=xxx
NOTION_CALENDAR_DATABASE_ID=xxx
TWILIO_ACCOUNT_SID=ACxxx
TWILIO_AUTH_TOKEN=xxx
TWILIO_WHATSAPP_FROM=whatsapp:+xxx
USE_META_WHATSAPP_API=false
NODE_ENV=production
PORT=3000
```

**⚠️ Nota:** Necesitarás configurar estas variables para cada ambiente (test/production). 