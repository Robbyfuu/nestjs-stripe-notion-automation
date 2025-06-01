#!/bin/bash

# 🔐 Script para cargar variables de entorno desde 1Password
# Asegúrate de tener 1Password CLI instalado y configurado

set -e

# Determinar ambiente
ENVIRONMENT=${NODE_ENV:-development}
echo "🎯 Cargando configuración para ambiente: $ENVIRONMENT"

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

# Cargar variables de entorno según el ambiente
echo "📥 Obteniendo credenciales de Stripe para $ENVIRONMENT..."

if [ "$ENVIRONMENT" = "production" ]; then
    # Credenciales de PRODUCCIÓN
    export STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API PROD" --field "Secret Key" --reveal 2>/dev/null || echo "")
    export STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook PROD" --field "Webhook Secret" --reveal 2>/dev/null || echo "")
    
    # Bases de datos de Notion para PRODUCCIÓN
    export NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases PROD" --field "Payments Database ID" 2>/dev/null || echo "")
    export NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases PROD" --field "Clients Database ID" 2>/dev/null || echo "")
    export NOTION_CALENDAR_DATABASE_ID=$(op item get "NestJS Notion Databases PROD" --field "Calendar Database ID" 2>/dev/null || echo "")
else
    # Credenciales de DESARROLLO/TEST
    export STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API" --field "Secret Key" --reveal 2>/dev/null || echo "")
    export STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal 2>/dev/null || echo "")
    
    # Bases de datos de Notion para DESARROLLO
    export NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Payments Database ID" 2>/dev/null || echo "")
    export NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Clients Database ID" 2>/dev/null || echo "")
    export NOTION_CALENDAR_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Calendar Database ID" 2>/dev/null || echo "")
fi

echo "📥 Obteniendo credenciales de Notion (compartidas)..."
export NOTION_SECRET=$(op item get "NestJS Notion Integration" --field "Integration Secret" --reveal 2>/dev/null || echo "")

# Variables locales
export PORT=3000
export NODE_ENV=$ENVIRONMENT

# Verificar que las variables críticas estén disponibles
missing_vars=()

if [ -z "$STRIPE_SECRET_KEY" ]; then
    missing_vars+=("STRIPE_SECRET_KEY ($ENVIRONMENT)")
fi

if [ -z "$STRIPE_WEBHOOK_SECRET" ]; then
    missing_vars+=("STRIPE_WEBHOOK_SECRET ($ENVIRONMENT)")
fi

if [ -z "$NOTION_SECRET" ]; then
    missing_vars+=("NOTION_SECRET (shared)")
fi

if [ -z "$NOTION_PAYMENTS_DATABASE_ID" ]; then
    missing_vars+=("NOTION_PAYMENTS_DATABASE_ID ($ENVIRONMENT)")
fi

if [ -z "$NOTION_CLIENTS_DATABASE_ID" ]; then
    missing_vars+=("NOTION_CLIENTS_DATABASE_ID ($ENVIRONMENT)")
fi

if [ -z "$NOTION_CALENDAR_DATABASE_ID" ]; then
    missing_vars+=("NOTION_CALENDAR_DATABASE_ID ($ENVIRONMENT)")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Variables de entorno faltantes en 1Password para $ENVIRONMENT:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "💡 Ejecuta el script de configuración: ./scripts/setup-1password.sh"
    exit 1
fi

echo "✅ Variables de entorno para $ENVIRONMENT cargadas exitosamente"
echo ""

# Ejecutar el comando solicitado o start:dev por defecto
if [ $# -eq 0 ]; then
    echo "🚀 Iniciando aplicación en modo $ENVIRONMENT..."
    if [ "$ENVIRONMENT" = "production" ]; then
        pnpm run start:prod
    else
        pnpm run start:dev
    fi
else
    echo "🚀 Ejecutando: $@"
    exec "$@"
fi 