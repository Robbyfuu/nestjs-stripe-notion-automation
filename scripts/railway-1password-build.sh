#!/bin/bash

# 🚂 Railway Build with 1Password Integration
# Carga variables de entorno desde 1Password y hace build
# Compatible con Alpine Linux (Docker)

set -e

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

print_log() {
    local color=$1
    local message=$2
    echo -e "${color}[RAILWAY-1PASSWORD] ${message}${NC}"
}

print_log $BLUE "🚂 Railway Build con 1Password - Iniciando..."

# Determinar ambiente basado en RAILWAY_ENVIRONMENT
ENVIRONMENT=${RAILWAY_ENVIRONMENT:-"production"}
print_log $YELLOW "📍 Ambiente detectado: $ENVIRONMENT"

# Verificar que tengamos OP_SERVICE_ACCOUNT_TOKEN
if [[ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]]; then
    print_log $RED "❌ OP_SERVICE_ACCOUNT_TOKEN no configurado en Railway"
    print_log $YELLOW "💡 Configura esta variable en Railway Dashboard para usar 1Password"
    print_log $YELLOW "🔄 Continuando con build normal sin variables de 1Password..."
    pnpm run build
    exit 0
fi

print_log $BLUE "🔐 OP_SERVICE_ACCOUNT_TOKEN encontrado"

# Verificar si 1Password CLI ya está instalado (debería estar desde Dockerfile)
if ! command -v op &> /dev/null; then
    print_log $RED "❌ 1Password CLI no encontrado en container"
    print_log $YELLOW "🔄 Continuando con build normal..."
    pnpm run build
    exit 0
fi

print_log $GREEN "✅ 1Password CLI disponible"

# Función para cargar una variable de 1Password
load_env_var() {
    local var_name=$1
    local op_reference=$2
    
    print_log $BLUE "📥 Cargando $var_name..."
    local value=$(op read "$op_reference" 2>/dev/null || echo "")
    
    if [[ -n "$value" ]]; then
        export $var_name="$value"
        print_log $GREEN "✅ $var_name cargado"
    else
        print_log $YELLOW "⚠️ No se pudo cargar $var_name, omitiendo..."
    fi
}

print_log $BLUE "🔐 Cargando variables de entorno desde 1Password..."

# === STRIPE ===
if [[ "$ENVIRONMENT" == "production" ]]; then
    load_env_var "STRIPE_SECRET_KEY" "op://Programing/NestJS Stripe API PROD/Secret Key"
    load_env_var "STRIPE_WEBHOOK_SECRET" "op://Programing/NestJS Stripe Webhook PROD/Webhook Secret"
else
    load_env_var "STRIPE_SECRET_KEY" "op://Programing/NestJS Stripe API TEST/Secret Key"
    load_env_var "STRIPE_WEBHOOK_SECRET" "op://Programing/NestJS Stripe Webhook TEST/Webhook Secret"
fi

# === NOTION ===
load_env_var "NOTION_SECRET" "op://Programing/NestJS Notion Integration/Secret"

if [[ "$ENVIRONMENT" == "production" ]]; then
    load_env_var "NOTION_CLIENTS_DATABASE_ID" "op://Programing/NestJS Notion Databases PROD/Clients Database ID"
    load_env_var "NOTION_PAYMENTS_DATABASE_ID" "op://Programing/NestJS Notion Databases PROD/Payments Database ID"
    load_env_var "NOTION_CALENDAR_DATABASE_ID" "op://Programing/NestJS Notion Databases PROD/Calendar Database ID"
else
    load_env_var "NOTION_CLIENTS_DATABASE_ID" "op://Programing/NestJS Notion Databases TEST/Clients Database ID"
    load_env_var "NOTION_PAYMENTS_DATABASE_ID" "op://Programing/NestJS Notion Databases TEST/Payments Database ID"
    load_env_var "NOTION_CALENDAR_DATABASE_ID" "op://Programing/NestJS Notion Databases TEST/Calendar Database ID"
fi

# === WHATSAPP (COMPARTIDO) ===
load_env_var "TWILIO_ACCOUNT_SID" "op://Programing/NestJS WhatsApp Twilio/Account SID"
load_env_var "TWILIO_AUTH_TOKEN" "op://Programing/NestJS WhatsApp Twilio/Auth Token"
load_env_var "TWILIO_WHATSAPP_FROM" "op://Programing/NestJS WhatsApp Twilio/WhatsApp From"
load_env_var "USE_META_WHATSAPP_API" "op://Programing/NestJS WhatsApp Meta/Use Meta API"

# === ENVIRONMENT CONFIG ===
export NODE_ENV="$ENVIRONMENT"
export PORT="3000"

print_log $GREEN "✅ Variables de entorno cargadas desde 1Password"
print_log $BLUE "🔨 Iniciando build de NestJS..."

# Hacer el build
pnpm run build

print_log $GREEN "🎉 Build completado con variables de 1Password!"
print_log $YELLOW "💡 Variables cargadas para ambiente: $ENVIRONMENT" 