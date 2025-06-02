#!/bin/bash

# 🚂 Railway Debug Script
# =======================

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
    echo -e "${color}[RAILWAY-DEBUG] ${message}${NC}"
}

print_log $BLUE "🚂 Railway API Debug - Investigando el problema"

# Verificar token
if [[ -z "$RAILWAY_TOKEN" ]]; then
    print_log $RED "❌ RAILWAY_TOKEN no está configurado"
    read -p "🔑 Ingresa tu Railway token: " user_token
    export RAILWAY_TOKEN="$user_token"
fi

# Función GraphQL con debug
railway_graphql_debug() {
    local query=$1
    local variables=${2:-"{}"}
    
    print_log $BLUE "📤 Enviando query a Railway..."
    echo "Query: $query"
    echo "Variables: $variables"
    
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\", \"variables\": $variables}" \
        "https://backboard.railway.com/graphql/v2")
    
    print_log $BLUE "📥 Respuesta de Railway:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    
    return 0
}

# Test 1: Verificar autenticación
print_log $BLUE "🔐 Test 1: Verificando autenticación..."
auth_query='query { me { id name email } }'
railway_graphql_debug "$auth_query"

echo ""
print_log $BLUE "🏗️ Test 2: Verificando proyectos..."
projects_query='query { projects { edges { node { id name } } } }'
railway_graphql_debug "$projects_query"

echo ""
print_log $BLUE "🎯 Test 3: Probando una variable simple..."

# IDs del proyecto (usando los que tienes)
PROJECT_ID="17d7d311-9966-437e-9a1f-6e286c1ec806"
TEST_ENV_ID="adf9a40c-0522-40bc-99f3-41170b67fe31"
TEST_SERVICE_ID="466df4c3-48c1-4b14-adce-6c3a76c56314"

print_log $YELLOW "Usando IDs:"
echo "Project: $PROJECT_ID"
echo "Environment: $TEST_ENV_ID"
echo "Service: $TEST_SERVICE_ID"

# Test variable simple
test_query='mutation VariableUpsert($input: VariableUpsertInput!) { variableUpsert(input: $input) }'
test_variables="{\"input\": {\"projectId\": \"$PROJECT_ID\", \"environmentId\": \"$TEST_ENV_ID\", \"serviceId\": \"$TEST_SERVICE_ID\", \"name\": \"TEST_VAR\", \"value\": \"test_value\"}}"

railway_graphql_debug "$test_query" "$test_variables"

echo ""
print_log $BLUE "🔍 Test 4: Verificando variables existentes..."
vars_query="query { variables(projectId: \"$PROJECT_ID\", environmentId: \"$TEST_ENV_ID\", serviceId: \"$TEST_SERVICE_ID\") }"
railway_graphql_debug "$vars_query"

echo ""
print_log $YELLOW "💡 Análisis:"
echo "1. Si Test 1 falla → Problema de autenticación/token"
echo "2. Si Test 2 falla → Token sin permisos de proyecto"
echo "3. Si Test 3 falla → IDs incorrectos o problema de permisos"
echo "4. Si Test 4 falla → Proyecto/servicio no existe"

echo ""
print_log $BLUE "📋 Próximos pasos según resultados:"
echo "- Error 401: Token inválido o expirado"
echo "- Error 403: Token sin permisos suficientes"
echo "- Error 404: IDs incorrectos"
echo "- Errores de GraphQL: Schema incorrecto" 