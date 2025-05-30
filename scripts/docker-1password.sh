#!/bin/bash

# 🐳 Script para ejecutar Docker con variables de 1Password
# Carga las variables desde 1Password y ejecuta Docker Compose

set -e

echo "🐳 Ejecutando Docker con 1Password"
echo "=================================="

# Verificar que 1Password CLI esté instalado
if ! command -v op &> /dev/null; then
    echo "❌ Error: 1Password CLI no está instalado"
    echo "💡 Instalar con: brew install --cask 1password/tap/1password-cli"
    exit 1
fi

# Verificar que esté autenticado
if ! op account list &> /dev/null; then
    echo "🔑 Iniciando sesión en 1Password..."
    eval $(op signin)
fi

# Cargar variables de entorno desde 1Password
echo "📥 Obteniendo credenciales desde 1Password..."

# Determinar si usar credenciales de test o producción
if [ "${NODE_ENV:-development}" = "production" ]; then
    echo "🏭 Usando credenciales de PRODUCCIÓN"
    STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API PROD" --field "Secret Key" --reveal 2>/dev/null || op item get "NestJS Stripe API" --field "Secret Key" --reveal)
    STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook PROD" --field "Webhook Secret" --reveal 2>/dev/null || op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal)
else
    echo "🧪 Usando credenciales de TEST"
    STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API" --field "Secret Key" --reveal 2>/dev/null || echo "")
    STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal 2>/dev/null || echo "")
fi

# Notion es compartido entre ambientes
NOTION_SECRET=$(op item get "NestJS Notion Integration" --field "Integration Secret" --reveal 2>/dev/null || echo "")
NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Payments Database ID" 2>/dev/null || echo "")
NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Clients Database ID" 2>/dev/null || echo "")

# Exportar variables para uso en Docker
export STRIPE_SECRET_KEY
export STRIPE_WEBHOOK_SECRET
export NOTION_SECRET
export NOTION_PAYMENTS_DATABASE_ID
export NOTION_CLIENTS_DATABASE_ID

# Variables locales
export PORT=3000
export NODE_ENV=${NODE_ENV:-development}

# Verificar que al menos las variables críticas estén disponibles
missing_vars=()

if [ -z "$STRIPE_SECRET_KEY" ]; then
    missing_vars+=("STRIPE_SECRET_KEY")
fi

if [ -z "$NOTION_SECRET" ]; then
    missing_vars+=("NOTION_SECRET")
fi

# Si faltan variables críticas, crear .env con valores demo
if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "⚠️  Algunas variables no están en 1Password:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "🔧 Creando archivo .env con valores demo para testing..."
    
    cat > .env << EOF
STRIPE_SECRET_KEY=sk_test_demo_key_for_testing_only
STRIPE_WEBHOOK_SECRET=whsec_demo_secret_for_testing_only
NOTION_SECRET=secret_demo_notion_key_for_testing_only
NOTION_PAYMENTS_DATABASE_ID=demo123456789012345678901234567890
NOTION_CLIENTS_DATABASE_ID=demo098765432109876543210987654321
PORT=3000
NODE_ENV=${NODE_ENV:-development}
EOF
    
    echo "✅ Archivo .env creado con valores demo"
else
    echo "✅ Variables cargadas desde 1Password"
    
    # Crear archivo .env con las variables reales
    cat > .env << EOF
STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET=$STRIPE_WEBHOOK_SECRET
NOTION_SECRET=$NOTION_SECRET
NOTION_PAYMENTS_DATABASE_ID=$NOTION_PAYMENTS_DATABASE_ID
NOTION_CLIENTS_DATABASE_ID=$NOTION_CLIENTS_DATABASE_ID
PORT=3000
NODE_ENV=${NODE_ENV:-development}
EOF
fi

echo ""

# Determinar modo de ejecución
MODE=${1:-dev}

case $MODE in
    "dev"|"development")
        echo "🚀 Iniciando Docker en modo DESARROLLO..."
        echo "   - Hot reload habilitado"
        echo "   - Debug port: 9229"
        echo "   - Redis dev: 6380"
        echo ""
        docker-compose -f docker-compose.dev.yml up --build
        ;;
    "prod"|"production")
        echo "🏭 Iniciando Docker en modo PRODUCCIÓN..."
        echo "   - Imagen optimizada"
        echo "   - Redis: 6379"
        echo "   - Health checks habilitados"
        echo "   - Logs en ./logs/"
        echo ""
        # Crear directorio de logs si no existe
        mkdir -p logs
        docker-compose up --build -d
        echo ""
        echo "✅ Aplicación iniciada en segundo plano"
        echo "📊 Ver logs: docker-compose logs -f nestjs-stripe"
        echo "🔍 Verificar salud: curl http://localhost:3000/health"
        ;;
    *)
        echo "❌ Modo no válido: $MODE"
        echo "💡 Uso: $0 [dev|prod]"
        echo "   dev  - Modo desarrollo (por defecto)"
        echo "   prod - Modo producción"
        exit 1
        ;;
esac 