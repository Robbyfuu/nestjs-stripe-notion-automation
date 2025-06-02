#!/bin/bash

# 🚂 Railway Complete Auto Setup
# ===============================

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
    echo -e "${color}[RAILWAY-AUTO] ${message}${NC}"
}

print_log $BLUE "🚂 Railway Complete Auto Setup - Todo en uno"

# Verificar dependencias
check_dependencies() {
    local missing_deps=()
    
    if ! command -v op &> /dev/null; then
        missing_deps+=("1Password CLI")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_log $RED "❌ Dependencias faltantes: ${missing_deps[*]}"
        print_log $YELLOW "💡 Instala las dependencias faltantes"
        
        # Auto-instalar jq en macOS
        if [[ "$OSTYPE" == "darwin"* ]] && ! command -v jq &> /dev/null; then
            print_log $BLUE "📦 Instalando jq..."
            brew install jq
        fi
        
        exit 1
    fi
    
    print_log $GREEN "✅ Todas las dependencias están instaladas"
}

# Verificar 1Password
check_1password() {
    if ! op account list &> /dev/null; then
        print_log $RED "❌ No hay sesión activa de 1Password"
        print_log $YELLOW "💡 Ejecuta: op signin"
        exit 1
    fi
    print_log $GREEN "✅ 1Password listo"
}

# Verificar Railway token
check_railway_token() {
    if [[ -z "$RAILWAY_TOKEN" ]]; then
        print_log $YELLOW "⚠️  RAILWAY_TOKEN no está configurado"
        echo ""
        echo "📋 Opciones:"
        echo "1) Configurar token manualmente"
        echo "2) Usar railway login"
        echo ""
        read -p "Selecciona una opción (1-2): " token_choice
        
        case $token_choice in
            1)
                read -p "🔑 Ingresa tu Railway token: " user_token
                export RAILWAY_TOKEN="$user_token"
                ;;
            2)
                print_log $BLUE "🔑 Iniciando railway login..."
                railway login
                # El token se guarda en railway CLI, pero necesitamos exportarlo
                print_log $YELLOW "💡 Después de login, exporta el token para este script"
                exit 1
                ;;
            *)
                print_log $RED "❌ Opción inválida"
                exit 1
                ;;
        esac
    fi
    
    print_log $GREEN "✅ Railway token configurado"
}

# Función GraphQL
railway_graphql() {
    local query=$1
    local variables=${2:-"{}"}
    
    curl -s -X POST \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\", \"variables\": $variables}" \
        "https://backboard.railway.com/graphql/v2"
}

# Configurar variable
upsert_variable() {
    local project_id=$1
    local environment_id=$2
    local service_id=$3
    local name=$4
    local value=$5
    
    local query='mutation VariableUpsert($input: VariableUpsertInput!) { variableUpsert(input: $input) }'
    local variables="{\"input\": {\"projectId\": \"$project_id\", \"environmentId\": \"$environment_id\", \"serviceId\": \"$service_id\", \"name\": \"$name\", \"value\": \"$value\"}}"
    
    railway_graphql "$query" "$variables"
}

# Procesar archivo 1Password y subir a Railway
process_env_file() {
    local input_file=$1
    local project_id=$2
    local environment_id=$3
    local service_id=$4
    local env_name=$5
    
    print_log $BLUE "🚀 Procesando $env_name desde $input_file"
    
    if [[ ! -f "$input_file" ]]; then
        print_log $RED "❌ Archivo no encontrado: $input_file"
        return 1
    fi
    
    local success_count=0
    local total_count=0
    
    while IFS='=' read -r key value; do
        # Saltar líneas vacías y comentarios
        [[ -z "$key" || "$key" == \#* ]] && continue
        
        # Limpiar valor
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        
        # Resolver 1Password
        if [[ "$value" == op://* ]]; then
            print_log $BLUE "🔑 $key"
            resolved_value=$(op read "$value" 2>/dev/null || echo "")
            if [[ -n "$resolved_value" ]]; then
                value="$resolved_value"
            else
                print_log $RED "❌ No se pudo resolver: $key"
                continue
            fi
        fi
        
        # Subir a Railway
        response=$(upsert_variable "$project_id" "$environment_id" "$service_id" "$key" "$value")
        
        if echo "$response" | jq -e '.data.variableUpsert' > /dev/null 2>&1; then
            print_log $GREEN "✅ $key"
            ((success_count++))
        else
            print_log $RED "❌ Error: $key"
        fi
        
        ((total_count++))
        sleep 0.3  # Rate limiting
        
    done < "$input_file"
    
    print_log $GREEN "🎉 $env_name: $success_count/$total_count variables configuradas"
}

# Script principal
main() {
    print_log $BLUE "🔧 Verificando dependencias..."
    check_dependencies
    check_1password
    check_railway_token
    
    echo ""
    print_log $BLUE "🎯 Configuración automática - ¿Qué entornos?"
    echo "1) Test solamente"
    echo "2) Production solamente"
    echo "3) Ambos (Test + Production)"
    echo ""
    read -p "Selecciona una opción (1-3): " env_choice
    
    # Necesitamos los IDs una sola vez
    echo ""
    print_log $YELLOW "📝 Configuración de IDs (solo la primera vez)"
    print_log $BLUE "💡 Ve a https://railway.app → Tu proyecto para obtener estos IDs"
    echo ""
    
    read -p "🏗️  PROJECT_ID: " PROJECT_ID
    
    case $env_choice in
        1|3)
            read -p "🧪 TEST_ENVIRONMENT_ID: " TEST_ENV_ID
            read -p "🧪 TEST_SERVICE_ID: " TEST_SERVICE_ID
            ;;
    esac
    
    case $env_choice in
        2|3)
            read -p "🏭 PROD_ENVIRONMENT_ID: " PROD_ENV_ID
            read -p "🏭 PROD_SERVICE_ID: " PROD_SERVICE_ID
            ;;
    esac
    
    echo ""
    print_log $BLUE "🚀 Comenzando configuración automática..."
    
    case $env_choice in
        1)
            process_env_file "1password-test.env" "$PROJECT_ID" "$TEST_ENV_ID" "$TEST_SERVICE_ID" "TEST"
            ;;
        2)
            process_env_file "1password-prod.env" "$PROJECT_ID" "$PROD_ENV_ID" "$PROD_SERVICE_ID" "PRODUCTION"
            ;;
        3)
            process_env_file "1password-test.env" "$PROJECT_ID" "$TEST_ENV_ID" "$TEST_SERVICE_ID" "TEST"
            process_env_file "1password-prod.env" "$PROJECT_ID" "$PROD_ENV_ID" "$PROD_SERVICE_ID" "PRODUCTION"
            ;;
        *)
            print_log $RED "❌ Opción inválida"
            exit 1
            ;;
    esac
    
    echo ""
    print_log $GREEN "🎉 ¡Configuración automática completada!"
    print_log $BLUE "📚 Próximos pasos:"
    echo "1. Verifica variables en Railway UI"
    echo "2. Configura RAILWAY_TOKEN en GitHub Secrets"
    echo "3. Push a 'test' → Deploy automático"
    echo "4. Push a 'main' → Deploy automático"
    echo ""
    print_log $GREEN "🚂 ¡Railway listo para CI/CD!"
}

# Ejecutar script principal
main "$@" 