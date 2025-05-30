#!/bin/bash

# 🧪 Script para probar la configuración de 1Password
# Verifica que las entradas estén creadas correctamente

set -e

echo "🧪 Probando configuración de 1Password"
echo "======================================"

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

echo ""
echo "🔍 Verificando entradas en 1Password..."

# Lista de entradas esperadas
entries=(
    "NestJS Stripe API"
    "NestJS Stripe Webhook" 
    "NestJS Notion Integration"
    "NestJS Notion Databases"
)

missing_entries=()
found_entries=()

for entry in "${entries[@]}"; do
    if op item get "$entry" &>/dev/null; then
        found_entries+=("$entry")
        echo "✅ Encontrado: $entry"
    else
        missing_entries+=("$entry")
        echo "❌ Faltante: $entry"
    fi
done

echo ""
echo "📊 Resumen:"
echo "   Entradas encontradas: ${#found_entries[@]}"
echo "   Entradas faltantes: ${#missing_entries[@]}"

if [ ${#missing_entries[@]} -gt 0 ]; then
    echo ""
    echo "❌ Entradas faltantes en 1Password:"
    printf '   - %s\n' "${missing_entries[@]}"
    echo ""
    echo "💡 Ejecuta: pnpm run setup:1password"
    exit 1
else
    echo ""
    echo "🎉 ¡Todas las entradas están configuradas!"
    echo ""
    echo "📋 Prueba la carga de variables:"
    echo "   pnpm run start:dev:1password"
fi 