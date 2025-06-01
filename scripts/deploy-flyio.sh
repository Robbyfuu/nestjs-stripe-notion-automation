#!/bin/bash

# 🚀 Script para desplegar en Fly.io con configuración desde 1Password
# Configura variables de entorno y despliega la aplicación

set -e

echo "🚀 Deployment en Fly.io - NestJS Stripe Notion"
echo "=============================================="

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [AMBIENTE] [OPCIONES]"
    echo ""
    echo "AMBIENTE:"
    echo "  dev     Despliega en ambiente de desarrollo"
    echo "  prod    Despliega en ambiente de producción"
    echo ""
    echo "OPCIONES:"
    echo "  -a, --app NAME    Nombre personalizado de la app"
    echo "  -h, --help        Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 dev"
    echo "  $0 prod"
    echo "  $0 dev --app mi-app-custom"
}

# Parsear argumentos
ENVIRONMENT=""
CUSTOM_APP_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|development)
            ENVIRONMENT="dev"
            shift
            ;;
        prod|production)
            ENVIRONMENT="prod"
            shift
            ;;
        -a|--app)
            CUSTOM_APP_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Argumento desconocido: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validar ambiente
if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Error: Debes especificar un ambiente (dev o prod)"
    show_help
    exit 1
fi

# Configurar nombres de app y archivos según ambiente
if [ "$ENVIRONMENT" = "dev" ]; then
    APP_NAME=${CUSTOM_APP_NAME:-"nestjs-stripe-notion-dev"}
    FLY_CONFIG="fly.dev.toml"
    NODE_ENV="development"
    echo "🧪 Desplegando en ambiente de DESARROLLO"
else
    APP_NAME=${CUSTOM_APP_NAME:-"nestjs-stripe-notion"}
    FLY_CONFIG="fly.toml"
    NODE_ENV="production"
    echo "🏭 Desplegando en ambiente de PRODUCCIÓN"
fi

echo "   App: $APP_NAME"
echo "   Config: $FLY_CONFIG"
echo ""

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

echo "🔍 Verificando credenciales en 1Password..."

# Función para obtener variables según ambiente
get_env_vars() {
    local env=$1
    
    if [ "$env" = "dev" ]; then
        echo "📥 Obteniendo credenciales de DESARROLLO desde 1Password..."
        
        # Stripe Development
        STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API" --field "Secret Key" --reveal 2>/dev/null || echo "")
        STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal 2>/dev/null || echo "")
        
        # Notion Shared
        NOTION_SECRET=$(op item get "NestJS Notion Integration" --field "Integration Secret" --reveal 2>/dev/null || echo "")
        
        # Notion Databases Development
        NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Clients Database ID" --reveal 2>/dev/null || echo "")
        NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Payments Database ID" --reveal 2>/dev/null || echo "")
        NOTION_CALENDAR_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Calendar Database ID" --reveal 2>/dev/null || echo "")
        
    else
        echo "📥 Obteniendo credenciales de PRODUCCIÓN desde 1Password..."
        
        # Stripe Production
        STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API PROD" --field "Secret Key" --reveal 2>/dev/null || echo "")
        STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook PROD" --field "Webhook Secret" --reveal 2>/dev/null || echo "")
        
        # Notion Shared
        NOTION_SECRET=$(op item get "NestJS Notion Integration" --field "Integration Secret" --reveal 2>/dev/null || echo "")
        
        # Notion Databases Production
        NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases PROD" --field "Clients Database ID" --reveal 2>/dev/null || echo "")
        NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases PROD" --field "Payments Database ID" --reveal 2>/dev/null || echo "")
        NOTION_CALENDAR_DATABASE_ID=$(op item get "NestJS Notion Databases PROD" --field "Calendar Database ID" --reveal 2>/dev/null || echo "")
    fi
}

# Obtener variables de entorno
get_env_vars "$ENVIRONMENT"

# Verificar credenciales críticas
missing_vars=()

if [ -z "$STRIPE_SECRET_KEY" ]; then
    missing_vars+=("Stripe Secret Key ($ENVIRONMENT)")
fi

if [ -z "$STRIPE_WEBHOOK_SECRET" ]; then
    missing_vars+=("Stripe Webhook Secret ($ENVIRONMENT)")
fi

if [ -z "$NOTION_SECRET" ]; then
    missing_vars+=("Notion Integration Secret")
fi

if [ -z "$NOTION_CLIENTS_DATABASE_ID" ]; then
    missing_vars+=("Notion Clients Database ID ($ENVIRONMENT)")
fi

if [ -z "$NOTION_PAYMENTS_DATABASE_ID" ]; then
    missing_vars+=("Notion Payments Database ID ($ENVIRONMENT)")
fi

if [ -z "$NOTION_CALENDAR_DATABASE_ID" ]; then
    missing_vars+=("Notion Calendar Database ID ($ENVIRONMENT)")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Credenciales faltantes en 1Password:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "💡 Ejecuta el script de configuración:"
    echo "   pnpm run setup:interactive"
    if [ "$ENVIRONMENT" = "dev" ]; then
        echo "   Luego selecciona opción 'c' (desarrollo)"
    else
        echo "   Luego selecciona opción 'p' (producción)"
    fi
    exit 1
fi

echo "✅ Credenciales verificadas en 1Password"

# Mostrar información de las credenciales (enmascaradas)
echo ""
echo "🔐 Variables configuradas:"
echo "   STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY:0:10}..."
echo "   STRIPE_WEBHOOK_SECRET: ${STRIPE_WEBHOOK_SECRET:0:10}..."
echo "   NOTION_SECRET: ${NOTION_SECRET:0:10}..."
echo "   NOTION_CLIENTS_DATABASE_ID: ${NOTION_CLIENTS_DATABASE_ID:0:8}...${NOTION_CLIENTS_DATABASE_ID: -8}"
echo "   NOTION_PAYMENTS_DATABASE_ID: ${NOTION_PAYMENTS_DATABASE_ID:0:8}...${NOTION_PAYMENTS_DATABASE_ID: -8}"
echo "   NOTION_CALENDAR_DATABASE_ID: ${NOTION_CALENDAR_DATABASE_ID:0:8}...${NOTION_CALENDAR_DATABASE_ID: -8}"
echo ""

# Verificar si la app ya existe
echo "🔍 Verificando aplicación en Fly.io..."

# Intentar obtener información de la app directamente
if flyctl apps show "$APP_NAME" &>/dev/null; then
    echo "✅ App '$APP_NAME' encontrada"
    EXISTING_APP=true
else
    # Verificar también en la lista de apps
    if flyctl apps list | grep -q "^$APP_NAME "; then
        echo "✅ App '$APP_NAME' encontrada en la lista"
        EXISTING_APP=true
    else
        echo "🆕 App '$APP_NAME' no existe, se creará"
        EXISTING_APP=false
    fi
fi

# Crear app si no existe
if [ "$EXISTING_APP" = false ]; then
    echo "🆕 Creando nueva aplicación en Fly.io..."
    
    # Verificar si el archivo de configuración tiene el nombre correcto
    if grep -q "app = \"$APP_NAME\"" "$FLY_CONFIG"; then
        echo "✅ $FLY_CONFIG configurado correctamente"
    else
        echo "🔧 Actualizando nombre de app en $FLY_CONFIG..."
        sed -i.bak "s/^app = .*/app = \"$APP_NAME\"/" "$FLY_CONFIG"
        rm -f "$FLY_CONFIG.bak"
    fi
    
    # Intentar crear la app con manejo de errores
    if flyctl apps create "$APP_NAME" 2>/tmp/flyctl_error.log; then
        echo "✅ App '$APP_NAME' creada"
    else
        echo "⚠️  Error creando aplicación:"
        cat /tmp/flyctl_error.log
        echo ""
        
        # Verificar si el error es por nombre ya tomado
        if grep -q "already been taken" /tmp/flyctl_error.log; then
            echo "💡 La aplicación '$APP_NAME' ya existe pero no tienes acceso."
            echo "   Opciones:"
            echo "   1. Usa un nombre diferente: $0 $ENVIRONMENT --app tu-nombre-personalizado"
            echo "   2. Solicita acceso a la aplicación existente"
            echo "   3. Elimina la aplicación existente si es tuya"
            echo ""
            exit 1
        else
            echo "❌ Error inesperado creando aplicación"
            exit 1
        fi
    fi
fi

# Configurar variables de entorno
echo "🔐 Configurando variables de entorno en Fly.io..."

flyctl secrets set \
    NODE_ENV="$NODE_ENV" \
    STRIPE_SECRET_KEY="$STRIPE_SECRET_KEY" \
    STRIPE_WEBHOOK_SECRET="$STRIPE_WEBHOOK_SECRET" \
    NOTION_SECRET="$NOTION_SECRET" \
    NOTION_CLIENTS_DATABASE_ID="$NOTION_CLIENTS_DATABASE_ID" \
    NOTION_PAYMENTS_DATABASE_ID="$NOTION_PAYMENTS_DATABASE_ID" \
    NOTION_CALENDAR_DATABASE_ID="$NOTION_CALENDAR_DATABASE_ID" \
    --app "$APP_NAME"

echo "✅ Variables de entorno configuradas"

# Desplegar aplicación
echo "🚀 Desplegando aplicación..."

flyctl deploy --config "$FLY_CONFIG" --app "$APP_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ¡Deployment exitoso!"
    echo "======================="
    echo ""
    echo "📊 Información de la aplicación:"
    echo "   App: $APP_NAME"
    echo "   Ambiente: $ENVIRONMENT"
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
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo "🔗 Próximos pasos para PRODUCCIÓN:"
        echo "   1. Configura webhook en Stripe Dashboard:"
        echo "      URL: https://$APP_NAME.fly.dev/webhook/stripe"
        echo "      Eventos: payment_intent.succeeded"
        echo "   2. Actualiza el webhook secret en 1Password"
        echo "   3. Redespliega: $0 prod"
    else
        echo "🔗 Próximos pasos para DESARROLLO:"
        echo "   1. Prueba la aplicación con datos de test"
        echo "   2. Verifica que las integraciones funcionen"
        echo "   3. Cuando esté listo, despliega a producción: $0 prod"
    fi
    echo ""
    echo "✅ Tu aplicación está lista en: https://$APP_NAME.fly.dev"
else
    echo "❌ Error en el deployment"
    echo "📊 Ver logs: flyctl logs --app $APP_NAME"
    exit 1
fi 