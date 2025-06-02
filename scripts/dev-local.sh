#!/bin/bash

# 🚀 Script de desarrollo local con 1Password
# ===========================================

set -e

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_log() {
    local color=$1
    local message=$2
    echo -e "${color}[DEV] ${message}${NC}"
}

print_log $BLUE "🚀 Iniciando desarrollo local con 1Password..."

# Verificar que 1Password CLI está disponible
if ! command -v op &> /dev/null; then
    echo "❌ Error: 1Password CLI no está instalado"
    echo "💡 Instalar con: brew install --cask 1password/tap/1password-cli"
    exit 1
fi

# Verificar sesión activa
if ! op account list &> /dev/null; then
    echo "🔑 Iniciando sesión en 1Password..."
    eval $(op signin)
fi

print_log $GREEN "✅ 1Password configurado correctamente"
print_log $BLUE "🔧 Cargando variables de entorno..."

# Ejecutar aplicación con variables de 1Password
exec op run --env-file=1password-dev.env -- pnpm run start:dev 