#!/bin/bash

# 🔐 1Password Environment Loader
# Carga variables de entorno directamente desde 1Password según el ambiente

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
    echo -e "${color}[1PASSWORD-ENV] ${message}${NC}"
}

# Determinar ambiente
ENVIRONMENT=${1:-"development"}

print_log $BLUE "🔐 Cargando variables de entorno desde 1Password..."
print_log $YELLOW "📍 Ambiente: $ENVIRONMENT"

# Función para cargar una variable de 1Password
load_env_var() {
    local var_name=$1
    local op_reference=$2
    
    print_log $BLUE "📥 Cargando $var_name..."
    export $var_name=$(op read "$op_reference")
}

# === RAILWAY DEPLOYMENT ===
load_env_var "RAILWAY_TOKEN" "op://Programing/Railway Deploy/Token"

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

print_log $GREEN "✅ Variables de entorno cargadas para ambiente: $ENVIRONMENT"
print_log $YELLOW "💡 Uso: source scripts/load-env-from-1password.sh [production|test|development]" 