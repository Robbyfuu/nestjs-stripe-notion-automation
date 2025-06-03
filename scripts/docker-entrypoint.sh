#!/bin/bash

# 🐳 Docker Entrypoint - NestJS con 1Password Runtime
# ===================================================

set -e

# Colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_log() {
    local color=$1
    local message=$2
    echo -e "${color}[DOCKER] ${message}${NC}"
}

print_log $BLUE "🚀 Iniciando aplicación NestJS..."

# ===================================
# 🔐 CARGAR VARIABLES DESDE 1PASSWORD
# ===================================
if [[ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]]; then
    print_log $BLUE "🔐 Cargando variables desde 1Password en runtime..."
    
    # Función para cargar una variable de 1Password
    load_env_var() {
        local var_name=$1
        local op_reference=$2
        
        local value=$(op read "$op_reference" 2>/dev/null || echo "")
        
        if [[ -n "$value" ]]; then
            export $var_name="$value"
            print_log $GREEN "✅ Runtime: $var_name cargado"
        else
            print_log $YELLOW "⚠️ Runtime: No se pudo cargar $var_name"
        fi
    }
    
    # Determinar ambiente
    ENVIRONMENT=${RAILWAY_ENVIRONMENT:-${NODE_ENV:-"production"}}
    print_log $YELLOW "📍 Runtime ambiente: $ENVIRONMENT"
    
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
    
    print_log $GREEN "🎉 Variables cargadas desde 1Password en runtime"
else
    print_log $YELLOW "⚠️ OP_SERVICE_ACCOUNT_TOKEN no disponible, usando variables de Railway"
fi

# ====================================
# 🔍 VERIFICAR VARIABLES DE ENTORNO
# ====================================

# Verificar variables de entorno críticas
check_env_var() {
    local var_name=$1
    local var_value="${!var_name}"
    
    if [[ -z "$var_value" ]]; then
        print_log $RED "❌ Variable $var_name no está configurada"
        return 1
    else
        # Enmascarar secretos
        if [[ $var_name == *"SECRET"* ]] || [[ $var_name == *"TOKEN"* ]] || [[ $var_name == *"KEY"* ]]; then
            local masked="${var_value:0:10}..."
            print_log $GREEN "✅ $var_name: $masked"
        else
            print_log $GREEN "✅ $var_name: $var_value"
        fi
        return 0
    fi
}

print_log $BLUE "🔍 Verificando variables de entorno..."

# Variables críticas de Stripe
check_env_var "STRIPE_SECRET_KEY" || exit 1
check_env_var "STRIPE_WEBHOOK_SECRET" || exit 1

# Variables de Notion
check_env_var "NOTION_SECRET" || exit 1
check_env_var "NOTION_CLIENTS_DATABASE_ID" || exit 1

# Variables de WhatsApp (al menos Twilio)
check_env_var "TWILIO_ACCOUNT_SID" || exit 1
check_env_var "TWILIO_AUTH_TOKEN" || exit 1

print_log $BLUE "🌍 Ambiente: ${NODE_ENV:-development}"
print_log $BLUE "🔌 Puerto: ${PORT:-3000}"
print_log $GREEN "🎉 Todas las variables configuradas correctamente"
print_log $GREEN "🚀 Iniciando aplicación NestJS..."

# Ejecutar la aplicación
exec "$@" 