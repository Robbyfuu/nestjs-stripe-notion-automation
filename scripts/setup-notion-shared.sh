#!/bin/bash

# 🔐 Script para configurar la integración de Notion (compartida entre ambientes)
# Este script configura la entrada de Notion que se usa tanto en development como production

set -e

echo "📚 Configurando integración de Notion (compartida)..."
echo ""

# Verificar que 1Password CLI esté instalado
if ! command -v op &> /dev/null; then
    echo "❌ Error: 1Password CLI no está instalado"
    echo "💡 Instalar con: brew install --cask 1password/tap/1password-cli"
    exit 1
fi

# Verificar que esté autenticado
if ! op account list &> /dev/null; then
    echo "🔑 Iniciando sesión en 1Password..."
    eval $(op signin)
fi

echo "📝 Esta integración de Notion se usará para AMBOS ambientes."
echo "💡 Solo necesitas configurar esto una vez."
echo ""

# Configurar Notion Integration Token
echo "1️⃣ Configurando Notion Integration Token..."
echo "   💡 Ve a: https://www.notion.so/my-integrations"
echo "   🆕 Crea una nueva integración: 'NestJS Stripe Automation'"
echo "   📋 Copia el 'Internal Integration Token' (empieza con 'secret_')"
echo ""
read -p "🔑 Ingresa tu Notion Integration Token: " notion_token

if [[ ! $notion_token =~ ^secret_ ]]; then
    echo "⚠️  Advertencia: El token no parece ser válido (no empieza con 'secret_')"
    read -p "¿Continuar de todos modos? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "❌ Cancelado por el usuario"
        exit 1
    fi
fi

# Crear entrada para Notion Integration
if op item get "NestJS Notion Integration" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Notion Integration" "Integration Secret[password]"="$notion_token"
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "API Credential" \
        --title "NestJS Notion Integration" \
        "Integration Secret[password]"="$notion_token" \
        --tags "nestjs,notion,shared"
fi

echo "✅ Notion Integration Token configurado"
echo ""

# Verificación final
echo "🔍 Verificando configuración..."

# Test de lectura de variable
notion_secret=$(op item get "NestJS Notion Integration" --field "Integration Secret" --reveal 2>/dev/null || echo "ERROR")

if [[ $notion_secret == "ERROR" ]]; then
    echo "❌ Error en la verificación. No se pudo leer el token de Notion."
    exit 1
fi

echo "✅ Integración de Notion configurada correctamente"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Configura credenciales específicas por ambiente:"
echo "      - Para desarrollo: pnpm run setup:dev"
echo "      - Para producción: pnpm run setup:prod"
echo "   2. Crea las bases de datos según docs/NOTION-SETUP.md"
echo "   3. Comparte las bases de datos con tu integración de Notion"
echo "" 