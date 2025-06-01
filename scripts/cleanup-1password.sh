#!/bin/bash

# 🧹 Script para limpiar entradas corruptas de 1Password
# Elimina campos con datos corruptos (códigos de color, mensajes debug)

set -e

# Colores para output
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

# Verificar 1Password CLI
if ! command -v op &> /dev/null; then
    print_color $RED "❌ Error: 1Password CLI no está instalado"
    exit 1
fi

if ! op account list &> /dev/null; then
    print_color $YELLOW "🔑 Iniciando sesión en 1Password..."
    eval $(op signin)
fi

print_color $CYAN "🧹 Limpiador de Entradas Corruptas de 1Password"
print_color $CYAN "=============================================="
echo ""

# Función para limpiar campos corruptos
clean_field() {
    local item_title="$1"
    local field_name="$2"
    
    if op item get "$item_title" &>/dev/null; then
        local current_value=$(op item get "$item_title" --field "$field_name" --reveal 2>/dev/null || echo "")
        
        # Verificar si el valor tiene códigos ANSI o mensajes corruptos
        if [[ $current_value == *"[0;"* ]] || [[ $current_value == *"Configurar:"* ]] || [[ $current_value == *"extraído:"* ]]; then
            print_color $YELLOW "🧹 Limpiando campo corrupto: $item_title -> $field_name"
            
            # Intentar extraer solo el ID limpio (32 caracteres hex)
            if [[ $current_value =~ ([0-9a-f]{32}) ]]; then
                local clean_id="${BASH_REMATCH[1]}"
                print_color $BLUE "   Encontrado ID limpio: ${clean_id:0:8}...${clean_id: -8}"
                
                # Actualizar con ID limpio
                if op item edit "$item_title" "${field_name}[text]"="$clean_id" &>/dev/null; then
                    print_color $GREEN "   ✅ Campo limpiado exitosamente"
                else
                    print_color $RED "   ❌ Error limpiando campo"
                fi
            else
                print_color $RED "   ❌ No se pudo extraer ID válido, eliminando campo..."
                # Eliminar el campo corrupto
                op item edit "$item_title" --delete-field "$field_name" &>/dev/null || true
                print_color $YELLOW "   ⚠️  Campo eliminado, necesitarás reconfigurarlo"
            fi
        else
            if [ -n "$current_value" ]; then
                print_color $GREEN "✅ Campo ya está limpio: $item_title -> $field_name"
            else
                print_color $YELLOW "⚠️  Campo vacío: $item_title -> $field_name"
            fi
        fi
    else
        print_color $RED "❌ Entrada no encontrada: $item_title"
    fi
}

print_color $YELLOW "🔍 Revisando entradas de bases de datos..."
echo ""

# Limpiar campos de desarrollo
print_color $BLUE "🧪 Revisando bases de datos de DESARROLLO:"
clean_field "NestJS Notion Databases" "Clients Database ID"
clean_field "NestJS Notion Databases" "Payments Database ID"
clean_field "NestJS Notion Databases" "Calendar Database ID"

echo ""

# Limpiar campos de producción
print_color $BLUE "🏭 Revisando bases de datos de PRODUCCIÓN:"
clean_field "NestJS Notion Databases PROD" "Clients Database ID"
clean_field "NestJS Notion Databases PROD" "Payments Database ID"
clean_field "NestJS Notion Databases PROD" "Calendar Database ID"

echo ""
print_color $GREEN "🎉 Limpieza completada!"
echo ""
print_color $CYAN "📋 Próximos pasos:"
print_color $WHITE "   1. Ejecuta: pnpm run setup:interactive"
print_color $WHITE "   2. Reconfigura las variables que necesiten valores"
print_color $WHITE "   3. Usa la opción 'v' para verificar que todo esté correcto"
echo "" 