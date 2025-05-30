#!/bin/bash

# 🔐 Script para cargar variables de entorno desde 1Password
# Asegúrate de tener 1Password CLI instalado y configurado

set -e

echo "🔐 Cargando variables de entorno desde 1Password..."

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
echo "📥 Obteniendo credenciales de Stripe..."
export STRIPE_SECRET_KEY=$(op item get "NestJS Stripe API" --field "Secret Key" 2>/dev/null || echo "")
export STRIPE_WEBHOOK_SECRET=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" 2>/dev/null || echo "")

echo "📥 Obteniendo credenciales de Notion..."
export NOTION_SECRET=$(op item get "NestJS Notion Integration" --field "Integration Secret" 2>/dev/null || echo "")
export NOTION_PAYMENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Payments Database ID" 2>/dev/null || echo "")
export NOTION_CLIENTS_DATABASE_ID=$(op item get "NestJS Notion Databases" --field "Clients Database ID" 2>/dev/null || echo "")

# Variables locales
export PORT=3000
export NODE_ENV=${NODE_ENV:-development}

# Verificar que las variables críticas estén disponibles
missing_vars=()

if [ -z "$STRIPE_SECRET_KEY" ]; then
    missing_vars+=("STRIPE_SECRET_KEY")
fi

if [ -z "$STRIPE_WEBHOOK_SECRET" ]; then
    missing_vars+=("STRIPE_WEBHOOK_SECRET")
fi

if [ -z "$NOTION_SECRET" ]; then
    missing_vars+=("NOTION_SECRET")
fi

if [ -z "$NOTION_PAYMENTS_DATABASE_ID" ]; then
    missing_vars+=("NOTION_PAYMENTS_DATABASE_ID")
fi

if [ -z "$NOTION_CLIENTS_DATABASE_ID" ]; then
    missing_vars+=("NOTION_CLIENTS_DATABASE_ID")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Variables de entorno faltantes en 1Password:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "💡 Ejecuta el script de configuración: ./scripts/setup-1password.sh"
    exit 1
fi

echo "✅ Variables de entorno cargadas exitosamente"
echo ""

# Ejecutar el comando solicitado o start:dev por defecto
if [ $# -eq 0 ]; then
    echo "🚀 Iniciando aplicación en modo desarrollo..."
    pnpm run start:dev
else
    echo "🚀 Ejecutando: $@"
    exec "$@"
fi 