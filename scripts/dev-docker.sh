#!/bin/bash

# 🐳 Desarrollo con Docker + 1Password
# ====================================

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
    echo -e "${color}[DEV-DOCKER] ${message}${NC}"
}

print_log $BLUE "🐳 Iniciando desarrollo con Docker + 1Password..."

# Verificar que Docker está ejecutándose
if ! docker info >/dev/null 2>&1; then
    print_log $RED "❌ Docker no está ejecutándose"
    print_log $YELLOW "💡 Inicia Docker Desktop y vuelve a intentar"
    exit 1
fi

# Verificar 1Password CLI
if ! command -v op &> /dev/null; then
    print_log $RED "❌ 1Password CLI no está instalado"
    print_log $YELLOW "💡 Instala con: brew install --cask 1password/tap/1password-cli"
    exit 1
fi

# Obtener Service Account Token
if [[ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]]; then
    print_log $YELLOW "🔐 OP_SERVICE_ACCOUNT_TOKEN no configurado"
    print_log $YELLOW "💡 Exporta tu Service Account Token:"
    print_log $YELLOW "   export OP_SERVICE_ACCOUNT_TOKEN=ops_..."
    print_log $YELLOW ""
    print_log $YELLOW "O ejecuta sin 1Password (variables manuales):"
    print_log $YELLOW "   docker-compose up"
    exit 1
fi

print_log $GREEN "✅ 1Password Service Account configurado"
print_log $BLUE "🚀 Iniciando contenedor de desarrollo..."

# Manejar argumentos
case "${1:-up}" in
    "up"|"start")
        print_log $BLUE "⬆️ Iniciando servicios..."
        docker-compose up "${@:2}"
        ;;
    "build")
        print_log $BLUE "🔨 Rebuilding container..."
        docker-compose build "${@:2}"
        ;;
    "rebuild")
        print_log $BLUE "🔄 Rebuild completo..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up
        ;;
    "logs")
        print_log $BLUE "📋 Mostrando logs..."
        docker-compose logs -f "${@:2}"
        ;;
    "shell"|"bash")
        print_log $BLUE "🐚 Abriendo shell en container..."
        docker-compose exec nestjs-dev bash
        ;;
    "test")
        print_log $BLUE "🧪 Ejecutando tests..."
        docker-compose exec nestjs-dev pnpm run test "${@:2}"
        ;;
    "down"|"stop")
        print_log $BLUE "⬇️ Deteniendo servicios..."
        docker-compose down "${@:2}"
        ;;
    "clean")
        print_log $BLUE "🧹 Limpiando todo..."
        docker-compose down --volumes --rmi all
        ;;
    *)
        print_log $YELLOW "🚀 Comandos disponibles:"
        echo "  ./scripts/dev-docker.sh up      # Iniciar desarrollo"
        echo "  ./scripts/dev-docker.sh build   # Solo build"
        echo "  ./scripts/dev-docker.sh rebuild # Rebuild completo"
        echo "  ./scripts/dev-docker.sh logs    # Ver logs"
        echo "  ./scripts/dev-docker.sh shell   # Abrir bash"
        echo "  ./scripts/dev-docker.sh test    # Ejecutar tests"
        echo "  ./scripts/dev-docker.sh down    # Detener"
        echo "  ./scripts/dev-docker.sh clean   # Limpiar todo"
        ;;
esac 