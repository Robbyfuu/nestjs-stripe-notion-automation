#!/bin/bash

# 🚂 Railway API Variable Uploader
# ================================

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
    echo -e "${color}[RAILWAY-API] ${message}${NC}"
}

print_log $BLUE "🚂 Configurando variables usando Railway GraphQL API"

# Verificar si jq está instalado
if ! command -v jq &> /dev/null; then
    print_log $YELLOW "⚠️  jq no está instalado"
    print_log $BLUE "📦 Instalando jq..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        apt-get update && apt-get install -y jq
    fi
    print_log $GREEN "✅ jq instalado"
fi

# Verificar si curl está instalado
if ! command -v curl &> /dev/null; then
    print_log $RED "❌ curl no está disponible"
    exit 1
fi

# Verificar si 1Password CLI está disponible
if ! command -v op &> /dev/null; then
    print_log $RED "❌ 1Password CLI no está disponible"
    print_log $YELLOW "💡 Instala 1Password CLI para automatizar la configuración"
    exit 1
fi

# Verificar sesión activa de 1Password
if ! op account list &> /dev/null; then
    print_log $RED "❌ No hay sesión activa de 1Password"
    print_log $YELLOW "💡 Ejecuta: op signin"
    exit 1
fi

print_log $GREEN "✅ Dependencias listas"

# Verificar token de Railway
if [[ -z "$RAILWAY_TOKEN" ]]; then
    print_log $RED "❌ RAILWAY_TOKEN no está configurado"
    print_log $YELLOW "💡 Configura tu token de Railway:"
    echo "  export RAILWAY_TOKEN=tu_railway_token_aquí"
    echo "  o ejecuta: railway login"
    exit 1
fi

print_log $GREEN "✅ Railway token configurado"

# URLs y configuración
RAILWAY_API_URL="https://backboard.railway.com"

# Función para hacer consultas GraphQL a Railway
railway_graphql() {
    local query=$1
    local variables=${2:-"{}"}
    
    curl -s -X POST \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\", \"variables\": $variables}" \
        "$RAILWAY_API_URL/graphql/v2"
}

# Función para obtener proyectos
get_projects() {
    local query='query { projects { edges { node { id name environments { edges { node { id name } } } services { edges { node { id name } } } } } } }'
    railway_graphql "$query"
}

# Función para configurar variable
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

# Función para procesar archivo .env y subir variables
upload_variables_from_file() {
    local input_file=$1
    local project_id=$2
    local environment_id=$3
    local service_id=$4
    local env_name=$5
    
    print_log $BLUE "🚀 Subiendo variables para $env_name"
    
    if [[ ! -f "$input_file" ]]; then
        print_log $RED "❌ Archivo no encontrado: $input_file"
        return 1
    fi
    
    local total_vars=0
    local success_vars=0
    
    # Procesar variables desde 1Password
    while IFS='=' read -r key value; do
        # Saltar líneas vacías y comentarios
        [[ -z "$key" || "$key" == \#* ]] && continue
        
        # Limpiar el valor de comillas
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        
        # Resolver variable de 1Password
        if [[ "$value" == op://* ]]; then
            print_log $BLUE "🔑 Resolviendo: $key"
            resolved_value=$(op read "$value" 2>/dev/null || echo "")
            if [[ -n "$resolved_value" ]]; then
                value="$resolved_value"
            else
                print_log $RED "❌ No se pudo resolver: $key"
                continue
            fi
        fi
        
        # Subir variable a Railway
        print_log $BLUE "📤 Subiendo: $key"
        response=$(upsert_variable "$project_id" "$environment_id" "$service_id" "$key" "$value")
        
        # Verificar respuesta
        if echo "$response" | jq -e '.data.variableUpsert' > /dev/null 2>&1; then
            print_log $GREEN "✅ $key configurado"
            ((success_vars++))
        else
            print_log $RED "❌ Error al configurar $key"
            echo "Respuesta: $response" | head -c 200
        fi
        
        ((total_vars++))
        
        # Pequeña pausa para no sobrecargar la API
        sleep 0.5
        
    done < "$input_file"
    
    print_log $GREEN "🎉 Variables configuradas: $success_vars/$total_vars para $env_name"
}

# Mostrar proyectos disponibles
print_log $BLUE "📋 Obteniendo proyectos de Railway..."
projects_response=$(get_projects)

if ! echo "$projects_response" | jq -e '.data.projects' > /dev/null 2>&1; then
    print_log $RED "❌ Error al obtener proyectos"
    echo "Respuesta: $projects_response"
    exit 1
fi

# Extraer información de proyectos
echo "$projects_response" | jq -r '.data.projects.edges[].node | "\(.id) \(.name)"' > /tmp/railway_projects.txt

print_log $GREEN "✅ Proyectos disponibles:"
while read -r project_id project_name; do
    echo "  📁 $project_name ($project_id)"
done < /tmp/railway_projects.txt

echo ""
read -p "🎯 Ingresa el ID del proyecto para nestjs-stripe: " PROJECT_ID

# Verificar qué entornos configurar
echo ""
print_log $BLUE "🎯 ¿Qué entornos quieres configurar automáticamente?"
echo "1) Test (nestjs-stripe-notion-test)"
echo "2) Production (nestjs-stripe-notion-prod)"
echo "3) Ambos"
echo ""
read -p "Selecciona una opción (1-3): " env_choice

# IDs que necesitarás configurar manualmente la primera vez
echo ""
print_log $YELLOW "📝 Necesitarás los IDs de entornos y servicios. Ve a Railway UI para obtenerlos:"
echo "🌐 https://railway.app → Tu proyecto → Settings"

read -p "🔧 ID del entorno PRODUCTION: " PROD_ENV_ID
read -p "🧪 ID del entorno TEST (si aplica): " TEST_ENV_ID
read -p "🏭 ID del servicio PRODUCTION: " PROD_SERVICE_ID
read -p "🧪 ID del servicio TEST (si aplica): " TEST_SERVICE_ID

case $env_choice in
    1)
        if [[ -n "$TEST_ENV_ID" && -n "$TEST_SERVICE_ID" ]]; then
            upload_variables_from_file "1password-test.env" "$PROJECT_ID" "$TEST_ENV_ID" "$TEST_SERVICE_ID" "TEST"
        else
            print_log $RED "❌ Faltan IDs para entorno TEST"
        fi
        ;;
    2)
        if [[ -n "$PROD_ENV_ID" && -n "$PROD_SERVICE_ID" ]]; then
            upload_variables_from_file "1password-prod.env" "$PROJECT_ID" "$PROD_ENV_ID" "$PROD_SERVICE_ID" "PRODUCTION"
        else
            print_log $RED "❌ Faltan IDs para entorno PRODUCTION"
        fi
        ;;
    3)
        if [[ -n "$TEST_ENV_ID" && -n "$TEST_SERVICE_ID" ]]; then
            upload_variables_from_file "1password-test.env" "$PROJECT_ID" "$TEST_ENV_ID" "$TEST_SERVICE_ID" "TEST"
        fi
        if [[ -n "$PROD_ENV_ID" && -n "$PROD_SERVICE_ID" ]]; then
            upload_variables_from_file "1password-prod.env" "$PROJECT_ID" "$PROD_ENV_ID" "$PROD_SERVICE_ID" "PRODUCTION"
        fi
        ;;
    *)
        print_log $RED "❌ Opción inválida"
        exit 1
        ;;
esac

# Limpiar archivos temporales
rm -f /tmp/railway_projects.txt

echo ""
print_log $GREEN "🚂 ¡Variables configuradas automáticamente en Railway!"
print_log $BLUE "📚 Próximos pasos:"
echo "1. Verifica las variables en Railway UI"
echo "2. Haz push a 'test' para deploy a TEST"
echo "3. Merge a 'main' para deploy a PRODUCTION"
echo "4. Verifica las apps en:"
echo "   - TEST: https://nestjs-stripe-notion-test.railway.app/health"
echo "   - PROD: https://nestjs-stripe-notion-prod.railway.app/health" 