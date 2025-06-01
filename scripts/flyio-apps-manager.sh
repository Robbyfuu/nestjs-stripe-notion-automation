#!/bin/bash

# 🛩️ Gestor de Aplicaciones Fly.io
# Script para listar, crear y gestionar aplicaciones de Fly.io

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

# Verificar Fly CLI
if ! command -v flyctl &> /dev/null; then
    print_color $RED "❌ Error: Fly CLI no está instalado"
    print_color $YELLOW "💡 Instalar con: brew install flyctl"
    exit 1
fi

if ! flyctl auth whoami &> /dev/null; then
    print_color $YELLOW "🔑 Iniciando sesión en Fly.io..."
    flyctl auth login
fi

show_help() {
    print_color $CYAN "🛩️ Gestor de Aplicaciones Fly.io"
    print_color $CYAN "==============================="
    echo ""
    print_color $WHITE "Uso: $0 [COMANDO] [OPCIONES]"
    echo ""
    print_color $YELLOW "COMANDOS:"
    print_color $WHITE "  list        Listar todas las aplicaciones"
    print_color $WHITE "  check       Verificar si existe una app específica"
    print_color $WHITE "  create      Crear nueva aplicación"
    print_color $WHITE "  delete      Eliminar aplicación"
    print_color $WHITE "  status      Ver estado de aplicación"
    print_color $WHITE "  suggest     Sugerir nombres disponibles"
    echo ""
    print_color $YELLOW "EJEMPLOS:"
    print_color $WHITE "  $0 list"
    print_color $WHITE "  $0 check nestjs-stripe-notion-dev"
    print_color $WHITE "  $0 create mi-app-personalizada"
    print_color $WHITE "  $0 delete mi-app-vieja"
    print_color $WHITE "  $0 suggest nestjs-stripe"
}

list_apps() {
    print_color $CYAN "📋 Aplicaciones en tu cuenta:"
    echo ""
    
    local apps_output=$(flyctl apps list 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$apps_output"
        echo ""
        
        local app_count=$(echo "$apps_output" | grep -c "^[a-z]" || echo "0")
        print_color $GREEN "Total: $app_count aplicaciones"
    else
        print_color $RED "❌ Error listando aplicaciones"
    fi
}

check_app() {
    local app_name="$1"
    if [ -z "$app_name" ]; then
        print_color $RED "❌ Debes especificar el nombre de la aplicación"
        return 1
    fi
    
    print_color $CYAN "🔍 Verificando aplicación: $app_name"
    echo ""
    
    if flyctl apps show "$app_name" &>/dev/null; then
        print_color $GREEN "✅ La aplicación '$app_name' existe y tienes acceso"
        echo ""
        flyctl apps show "$app_name"
    else
        print_color $YELLOW "❌ La aplicación '$app_name' no existe o no tienes acceso"
        
        # Verificar si existe pero sin acceso
        if flyctl apps create "$app_name" --dry-run 2>&1 | grep -q "already been taken"; then
            print_color $RED "⚠️  La aplicación existe pero pertenece a otra cuenta"
        else
            print_color $GREEN "✅ El nombre '$app_name' está disponible"
        fi
    fi
}

create_app() {
    local app_name="$1"
    if [ -z "$app_name" ]; then
        print_color $RED "❌ Debes especificar el nombre de la aplicación"
        return 1
    fi
    
    print_color $CYAN "🆕 Creando aplicación: $app_name"
    echo ""
    
    if flyctl apps create "$app_name"; then
        print_color $GREEN "✅ Aplicación '$app_name' creada exitosamente"
        echo ""
        print_color $BLUE "📋 Próximos pasos:"
        print_color $WHITE "   1. Actualiza fly.toml con: app = \"$app_name\""
        print_color $WHITE "   2. Deploy con: flyctl deploy --app $app_name"
    else
        print_color $RED "❌ Error creando aplicación '$app_name'"
    fi
}

delete_app() {
    local app_name="$1"
    if [ -z "$app_name" ]; then
        print_color $RED "❌ Debes especificar el nombre de la aplicación"
        return 1
    fi
    
    print_color $YELLOW "⚠️  ¿Estás seguro de eliminar '$app_name'?"
    print_color $RED "   Esta acción NO se puede deshacer"
    echo -n "Escribe 'yes' para confirmar: "
    read confirm
    
    if [ "$confirm" = "yes" ]; then
        print_color $CYAN "🗑️  Eliminando aplicación: $app_name"
        if flyctl apps destroy "$app_name" --yes; then
            print_color $GREEN "✅ Aplicación '$app_name' eliminada"
        else
            print_color $RED "❌ Error eliminando aplicación"
        fi
    else
        print_color $YELLOW "❌ Operación cancelada"
    fi
}

show_status() {
    local app_name="$1"
    if [ -z "$app_name" ]; then
        print_color $RED "❌ Debes especificar el nombre de la aplicación"
        return 1
    fi
    
    print_color $CYAN "📊 Estado de: $app_name"
    echo ""
    
    if flyctl status --app "$app_name"; then
        echo ""
        print_color $BLUE "🔗 URL: https://$app_name.fly.dev"
    else
        print_color $RED "❌ Error obteniendo estado de '$app_name'"
    fi
}

suggest_names() {
    local base_name="${1:-nestjs-stripe}"
    
    print_color $CYAN "💡 Sugerencias de nombres disponibles basadas en '$base_name':"
    echo ""
    
    local suggestions=(
        "$base_name-dev-$(date +%m%d)"
        "$base_name-prod-$(date +%m%d)"
        "$base_name-staging"
        "$base_name-test"
        "$base_name-demo"
        "${base_name}-v2"
        "${USER}-${base_name}"
        "${base_name}-$(whoami)"
    )
    
    for suggestion in "${suggestions[@]}"; do
        if flyctl apps create "$suggestion" --dry-run 2>&1 | grep -q "already been taken"; then
            print_color $RED "❌ $suggestion (tomado)"
        else
            print_color $GREEN "✅ $suggestion (disponible)"
        fi
    done
    
    echo ""
    print_color $BLUE "💡 Tip: Usa nombres únicos como tu-nombre-$base_name"
}

# Parsear comando
case "${1:-help}" in
    list|ls)
        list_apps
        ;;
    check|verify)
        check_app "$2"
        ;;
    create|new)
        create_app "$2"
        ;;
    delete|destroy|rm)
        delete_app "$2"
        ;;
    status|info)
        show_status "$2"
        ;;
    suggest|names)
        suggest_names "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_color $RED "❌ Comando desconocido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 