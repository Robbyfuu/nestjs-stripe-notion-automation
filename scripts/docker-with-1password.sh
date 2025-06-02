#!/bin/bash

# 🐳 Docker con 1Password - Resolver variables en el host
# ========================================================

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
    echo -e "${color}[HOST] ${message}${NC}"
}

# Verificar parámetros
if [[ $# -lt 2 ]]; then
    echo "Uso: $0 <environment> <docker-compose-service>"
    echo "Ejemplo: $0 dev nestjs-dev"
    exit 1
fi

ENV_NAME=$1
SERVICE_NAME=$2
ONEPASSWORD_ENV_FILE="1password-${ENV_NAME}.env"

print_log $BLUE "🚀 Preparando entorno Docker para $ENV_NAME"
print_log $BLUE "📁 Archivo de configuración: $ONEPASSWORD_ENV_FILE"

# Verificar si el archivo existe
if [[ ! -f "$ONEPASSWORD_ENV_FILE" ]]; then
    print_log $RED "❌ Archivo no encontrado: $ONEPASSWORD_ENV_FILE"
    exit 1
fi

# Verificar 1Password CLI
if ! command -v op &> /dev/null; then
    print_log $RED "❌ 1Password CLI no disponible"
    exit 1
fi

# Verificar sesión activa
if ! op account list &> /dev/null; then
    print_log $RED "❌ No hay sesión activa de 1Password"
    print_log $YELLOW "💡 Ejecuta: op signin"
    exit 1
fi

print_log $GREEN "✅ 1Password CLI listo"
print_log $BLUE "🔄 Resolviendo variables de 1Password..."

# Crear archivo .env temporal para docker-compose
DOCKER_ENV_FILE=".env.docker"
echo "# Variables resueltas de 1Password para Docker" > "$DOCKER_ENV_FILE"
echo "# Generado automáticamente - NO editar manualmente" >> "$DOCKER_ENV_FILE"
echo "" >> "$DOCKER_ENV_FILE"

# Procesar archivo línea por línea
while IFS='=' read -r key value; do
    # Saltar líneas vacías y comentarios
    [[ -z "$key" || "$key" == \#* ]] && continue
    
    # Limpiar el valor de comillas
    value=$(echo "$value" | sed 's/^"//;s/"$//')
    
    # Si es una referencia de 1Password, resolverla
    if [[ "$value" == op://* ]]; then
        print_log $BLUE "🔑 Resolviendo: $key"
        resolved_value=$(op read "$value" 2>/dev/null || echo "")
        if [[ -n "$resolved_value" ]]; then
            echo "$key=$resolved_value" >> "$DOCKER_ENV_FILE"
            print_log $GREEN "✅ $key resuelto"
        else
            print_log $RED "❌ No se pudo resolver: $key"
            rm -f "$DOCKER_ENV_FILE"
            exit 1
        fi
    else
        echo "$key=$value" >> "$DOCKER_ENV_FILE"
        print_log $GREEN "✅ $key (directo)"
    fi
done < "$ONEPASSWORD_ENV_FILE"

print_log $GREEN "🎉 Todas las variables resueltas correctamente"
print_log $BLUE "📝 Archivo .env creado: $DOCKER_ENV_FILE"
print_log $BLUE "🐳 Iniciando contenedor Docker..."

# Ejecutar docker-compose con archivo .env específico
docker-compose --env-file="$DOCKER_ENV_FILE" up "$SERVICE_NAME"

# Limpiar archivo temporal
rm -f "$DOCKER_ENV_FILE"
print_log $BLUE "🧹 Limpieza completada" 