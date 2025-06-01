#!/bin/bash

# 🧪 Script para testear la aplicación NestJS Stripe Notion
# Verifica que todos los endpoints y configuraciones funcionen correctamente

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Función para mostrar ayuda
show_help() {
    print_color $CYAN "🧪 Tester de Aplicación NestJS Stripe Notion"
    print_color $CYAN "============================================"
    echo ""
    print_color $WHITE "Uso: $0 [AMBIENTE] [OPCIONES]"
    echo ""
    print_color $YELLOW "AMBIENTES:"
    print_color $WHITE "  dev     Testear aplicación de desarrollo"
    print_color $WHITE "  prod    Testear aplicación de producción"
    echo ""
    print_color $YELLOW "OPCIONES:"
    print_color $WHITE "  -v, --verbose    Mostrar respuestas completas"
    print_color $WHITE "  -h, --help       Mostrar esta ayuda"
    echo ""
    print_color $YELLOW "EJEMPLOS:"
    print_color $WHITE "  $0 dev"
    print_color $WHITE "  $0 prod --verbose"
}

# Función para hacer una petición HTTP con timeout
make_request() {
    local url="$1"
    local expected_status="${2:-200}"
    local method="${3:-GET}"
    local timeout="${4:-10}"
    
    local response_file="/tmp/test_response_$$"
    local status_file="/tmp/test_status_$$"
    
    # Hacer la petición y capturar el status code por separado
    if status_code=$(curl -s -w "%{http_code}" -m "$timeout" -X "$method" "$url" -o "$response_file" 2>/dev/null); then
        if [ "$status_code" = "$expected_status" ]; then
            print_color $GREEN "  ✅ $method $url ($status_code)"
            if [ "$VERBOSE" = "true" ]; then
                echo "     Response: $(head -c 200 "$response_file")..."
            fi
        else
            print_color $RED "  ❌ $method $url ($status_code, esperado $expected_status)"
            if [ "$VERBOSE" = "true" ]; then
                echo "     Response: $(head -c 200 "$response_file")..."
            fi
        fi
    else
        print_color $RED "  ❌ $method $url (timeout o error de conexión)"
    fi
    
    rm -f "$response_file" "$status_file"
}

# Función para testear endpoints básicos
test_basic_endpoints() {
    local base_url="$1"
    
    print_color $BLUE "🌐 Testeando endpoints básicos..."
    
    # Health check
    make_request "$base_url/health" 200
    
    # Root endpoint
    make_request "$base_url/" 200
    
    # Webhook endpoint (debe devolver 405 para GET)
    make_request "$base_url/webhook/stripe" 405
}

# Función para testear configuración de Fly.io
test_flyio_config() {
    local app_name="$1"
    
    print_color $BLUE "⚙️ Verificando configuración de Fly.io..."
    
    # Status de la app
    if flyctl status --app "$app_name" >/dev/null 2>&1; then
        print_color $GREEN "  ✅ App $app_name está ejecutándose"
        
        # Verificar secrets
        local secrets_count=$(flyctl secrets list --app "$app_name" | grep -c "^[A-Z]" || echo "0")
        if [ "$secrets_count" -gt 5 ]; then
            print_color $GREEN "  ✅ Variables de entorno configuradas ($secrets_count secrets)"
        else
            print_color $YELLOW "  ⚠️  Pocas variables configuradas ($secrets_count secrets)"
        fi
    else
        print_color $RED "  ❌ App $app_name no está disponible"
    fi
}

# Función para testear conectividad con Notion (sin hacer cambios reales)
test_notion_connectivity() {
    local base_url="$1"
    
    print_color $BLUE "📚 Testeando conectividad con Notion..."
    
    # Endpoint para verificar configuración de Notion (si existe)
    make_request "$base_url/notion/health" 200
    
    # Si no existe el endpoint, es normal
    if [ $? -ne 0 ]; then
        print_color $YELLOW "  ℹ️  Endpoint /notion/health no implementado (normal)"
    fi
}

# Función principal de testing
run_tests() {
    local environment="$1"
    local app_name=""
    local base_url=""
    
    case $environment in
        dev|development)
            app_name="nestjs-stripe-notion-dev"
            base_url="https://nestjs-stripe-notion-dev.fly.dev"
            print_color $CYAN "🧪 Testeando ambiente de DESARROLLO"
            ;;
        prod|production)
            app_name="nestjs-stripe-notion"
            base_url="https://nestjs-stripe-notion.fly.dev"
            print_color $CYAN "🏭 Testeando ambiente de PRODUCCIÓN"
            ;;
        *)
            print_color $RED "❌ Ambiente no válido: $environment"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    print_color $WHITE "🎯 Objetivo: $base_url"
    print_color $WHITE "📱 App: $app_name"
    echo ""
    
    # Ejecutar tests
    test_basic_endpoints "$base_url"
    echo ""
    
    test_flyio_config "$app_name"
    echo ""
    
    test_notion_connectivity "$base_url"
    echo ""
    
    print_color $GREEN "🎉 Tests completados!"
    echo ""
    print_color $BLUE "📋 Para más información:"
    print_color $WHITE "   flyctl logs --app $app_name"
    print_color $WHITE "   flyctl status --app $app_name"
    print_color $WHITE "   $base_url/health"
}

# Parsear argumentos
ENVIRONMENT=""
VERBOSE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|development|prod|production)
            ENVIRONMENT="$1"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_color $RED "❌ Argumento desconocido: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verificar que se especificó un ambiente
if [ -z "$ENVIRONMENT" ]; then
    print_color $RED "❌ Debes especificar un ambiente (dev o prod)"
    show_help
    exit 1
fi

# Ejecutar tests
run_tests "$ENVIRONMENT" 