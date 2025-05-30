#!/bin/bash

# 🚀 Script para desplegar en Fly.io con configuración desde 1Password
# Configura variables de entorno y despliega la aplicación

set -e

echo "🚀 Deployment en Fly.io - NestJS Stripe Notion"
echo "=============================================="

# Verificar que Fly CLI esté instalado
if ! command -v flyctl &> /dev/null; then
    echo "❌ Error: Fly CLI no está instalado"
    echo "💡 Instalar con:"
    echo "   brew install flyctl"
    echo "   curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Verificar que 1Password CLI esté instalado
if ! command -v op &> /dev/null; then
    echo "❌ Error: 1Password CLI no está instalado"
    echo "💡 Instalar con: brew install --cask 1password/tap/1password-cli"
    exit 1
fi

# Verificar que esté autenticado en 1Password
if ! op account list &> /dev/null; then
    echo "🔑 Iniciando sesión en 1Password..."
    eval $(op signin)
fi

# Verificar login en Fly.io
if ! flyctl auth whoami &> /dev/null; then
    echo "🔑 Iniciando sesión en Fly.io..."
    flyctl auth login
fi

# Obtener nombre de la app (permitir override)
APP_NAME=${1:-"nestjs-stripe-notion"}

echo "🔍 Verificando credenciales en 1Password..."

# Verificar credenciales críticas
missing_vars=()

if ! op item get "NestJS Stripe API" --field "Secret Key" --reveal &> /dev/null; then
    missing_vars+=("STRIPE_SECRET_KEY")
fi

if ! op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal &> /dev/null; then
    missing_vars+=("STRIPE_WEBHOOK_SECRET")
fi

if ! op item get "NestJS Notion Integration" --field "Integration Secret" --reveal &> /dev/null; then
    missing_vars+=("NOTION_SECRET")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Credenciales faltantes en 1Password:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "💡 Ejecuta el script de configuración: pnpm run setup"
    exit 1
fi

echo "✅ Credenciales verificadas en 1Password"

# Obtener credenciales de 1Password según el ambiente
echo "📥 Obteniendo credenciales desde 1Password..."

# Determinar si usar credenciales de test o producción
if [ "${NODE_ENV:-production}" = "production" ]; then
    echo "🏭 Usando credenciales de PRODUCCIÓN"
    STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API PROD" --field "Secret Key" --reveal 2>/dev/null || op item get "NestJS Stripe API" --field "Secret Key" --reveal)
    STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook PROD" --field "Webhook Secret" --reveal 2>/dev/null || op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal)
else
    echo "🧪 Usando credenciales de TEST"
    STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API" --field "Secret Key" --reveal)
    STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal)
fi

# Notion es compartido entre ambientes
NOTION_SECRET=$(op item get "NestJS Notion Integration" --field "Integration Secret" --reveal)
NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Payments Database ID" 2>/dev/null || echo "")
NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Clients Database ID" 2>/dev/null || echo "")

# Verificar webhook secret para producción
if [[ $STRIPE_WEBHOOK_SECRET == whsec_9a07* ]]; then
    echo "⚠️  ADVERTENCIA: Usando webhook secret de desarrollo"
    echo ""
    echo "🔗 Para producción, necesitas configurar un webhook real en Stripe:"
    echo "   1. Ve a https://dashboard.stripe.com/webhooks"
    echo "   2. Agrega endpoint: https://$APP_NAME.fly.dev/webhook/stripe"
    echo "   3. Selecciona eventos: payment_intent.succeeded"
    echo "   4. Copia el signing secret y actualízalo en 1Password"
    echo ""
    read -p "¿Continuar con el webhook de desarrollo? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelado. Configura el webhook de producción primero."
        exit 1
    fi
fi

# Verificar si la app ya existe
echo "🔍 Verificando aplicación en Fly.io..."

if flyctl apps list | grep -q "^$APP_NAME "; then
    echo "✅ App '$APP_NAME' encontrada"
    EXISTING_APP=true
else
    echo "🆕 App '$APP_NAME' no existe, se creará"
    EXISTING_APP=false
fi

# Crear app si no existe
if [ "$EXISTING_APP" = false ]; then
    echo "🆕 Creando nueva aplicación en Fly.io..."
    
    # Verificar si fly.toml tiene el nombre correcto
    if grep -q "app = \"$APP_NAME\"" fly.toml; then
        echo "✅ fly.toml configurado correctamente"
    else
        echo "🔧 Actualizando nombre de app en fly.toml..."
        sed -i.bak "s/^app = .*/app = \"$APP_NAME\"/" fly.toml
        rm -f fly.toml.bak
    fi
    
    flyctl apps create "$APP_NAME"
    echo "✅ App '$APP_NAME' creada"
fi

# Configurar variables de entorno
echo "🔐 Configurando variables de entorno en Fly.io..."

flyctl secrets set \
    STRIPE_SECRET_KEY="$STRIPE_SECRET_KEY" \
    STRIPE_WEBHOOK_SECRET="$STRIPE_WEBHOOK_SECRET" \
    NOTION_SECRET="$NOTION_SECRET" \
    NOTION_PAYMENTS_DATABASE_ID="$NOTION_PAYMENTS_DATABASE_ID" \
    NOTION_CLIENTS_DATABASE_ID="$NOTION_CLIENTS_DATABASE_ID" \
    --app "$APP_NAME"

echo "✅ Variables de entorno configuradas"

# Desplegar aplicación
echo "🚀 Desplegando aplicación..."

flyctl deploy --app "$APP_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ¡Deployment exitoso!"
    echo "======================="
    echo ""
    echo "📊 Información de la aplicación:"
    echo "   App: $APP_NAME"
    echo "   URL: https://$APP_NAME.fly.dev"
    echo "   Webhook: https://$APP_NAME.fly.dev/webhook/stripe"
    echo "   Health: https://$APP_NAME.fly.dev/health"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   flyctl logs --app $APP_NAME             # Ver logs"
    echo "   flyctl status --app $APP_NAME           # Estado de la app"
    echo "   flyctl ssh console --app $APP_NAME      # Acceso SSH"
    echo "   flyctl scale count 1 --app $APP_NAME    # Escalar"
    echo ""
    echo "🔗 Próximos pasos:"
    echo "   1. Configura webhook en Stripe Dashboard:"
    echo "      URL: https://$APP_NAME.fly.dev/webhook/stripe"
    echo "      Eventos: payment_intent.succeeded"
    echo "   2. Actualiza el webhook secret en 1Password"
    echo "   3. Redespliega: flyctl deploy --app $APP_NAME"
    echo ""
    echo "✅ Tu aplicación está lista en: https://$APP_NAME.fly.dev"
else
    echo "❌ Error en el deployment"
    echo "📊 Ver logs: flyctl logs --app $APP_NAME"
    exit 1
fi 