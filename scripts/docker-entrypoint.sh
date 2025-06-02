#!/bin/bash

# 🐳 Docker Entrypoint - NestJS Simple
# ====================================

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