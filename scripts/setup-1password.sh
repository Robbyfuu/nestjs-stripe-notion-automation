#!/bin/bash

# 🔧 Script para configurar entradas de 1Password para NestJS Stripe Notion
# Este script te ayuda a crear las entradas necesarias en 1Password

set -e

echo "🔧 Configurando 1Password para NestJS Stripe Notion Automation"
echo "============================================================="

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
echo "📝 Vamos a crear las siguientes entradas en 1Password:"
echo "   1. NestJS Stripe API"
echo "   2. NestJS Stripe Webhook"
echo "   3. NestJS Notion Integration"
echo "   4. NestJS Notion Databases"
echo ""

# Función para leer input de forma segura
read_secret() {
    local prompt="$1"
    local varname="$2"
    echo -n "$prompt: "
    read -s value
    echo ""
    eval "$varname='$value'"
}

# Función para crear entrada en 1Password
create_item() {
    local title="$1"
    local username="$2"
    shift 2
    local fields=("$@")
    
    echo "🔐 Creando entrada: $title"
    
    # Construir comando op item create
    local cmd="op item create --category=login --title='$title'"
    
    if [ -n "$username" ]; then
        cmd="$cmd --username='$username'"
    fi
    
    # Agregar campos personalizados
    for field in "${fields[@]}"; do
        cmd="$cmd --field='$field'"
    done
    
    eval "$cmd" > /dev/null 2>&1
    echo "✅ Entrada '$title' creada exitosamente"
}

echo "1️⃣ Configurando Stripe API Keys"
echo "================================"
read_secret "Stripe Secret Key (sk_test_...)" STRIPE_SECRET_KEY

if [ -n "$STRIPE_SECRET_KEY" ]; then
    create_item "NestJS Stripe API" "" "Secret Key[password]=$STRIPE_SECRET_KEY"
fi

echo ""
echo "2️⃣ Configurando Stripe Webhook"
echo "==============================="
read_secret "Stripe Webhook Secret (whsec_...)" STRIPE_WEBHOOK_SECRET

if [ -n "$STRIPE_WEBHOOK_SECRET" ]; then
    create_item "NestJS Stripe Webhook" "" "Webhook Secret[password]=$STRIPE_WEBHOOK_SECRET"
fi

echo ""
echo "3️⃣ Configurando Notion Integration"
echo "==================================="
read_secret "Notion Integration Secret (secret_...)" NOTION_SECRET

if [ -n "$NOTION_SECRET" ]; then
    create_item "NestJS Notion Integration" "" "Integration Secret[password]=$NOTION_SECRET"
fi

echo ""
echo "4️⃣ Configurando Notion Databases"
echo "================================="
echo -n "Notion Payments Database ID: "
read NOTION_PAYMENTS_DB_ID
echo -n "Notion Clients Database ID: "
read NOTION_CLIENTS_DB_ID

if [ -n "$NOTION_PAYMENTS_DB_ID" ] || [ -n "$NOTION_CLIENTS_DB_ID" ]; then
    fields=()
    [ -n "$NOTION_PAYMENTS_DB_ID" ] && fields+=("Payments Database ID[text]=$NOTION_PAYMENTS_DB_ID")
    [ -n "$NOTION_CLIENTS_DB_ID" ] && fields+=("Clients Database ID[text]=$NOTION_CLIENTS_DB_ID")
    
    create_item "NestJS Notion Databases" "" "${fields[@]}"
fi

echo ""
echo "🎉 ¡Configuración completada!"
echo "============================================"
echo ""
echo "📋 Comandos disponibles:"
echo "   ./scripts/load-env-1password.sh                 # Ejecutar con env desde 1Password"
echo "   ./scripts/load-env-1password.sh pnpm run build  # Build con env desde 1Password"
echo "   ./scripts/load-env-1password.sh pnpm test       # Tests con env desde 1Password"
echo ""
echo "💡 También puedes agregar este alias a tu .zshrc:"
echo "   alias nest-dev='./scripts/load-env-1password.sh'" 