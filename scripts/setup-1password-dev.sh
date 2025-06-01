#!/bin/bash

# 🔐 Script para configurar credenciales de DESARROLLO en 1Password
# Este script configura las entradas específicas para el ambiente de desarrollo/test

set -e

echo "🔐 Configurando credenciales de DESARROLLO en 1Password..."
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

echo "📝 Las credenciales de desarrollo son SEPARADAS de producción."
echo "💡 Usa claves de TEST de Stripe (empiezan con 'sk_test_')"
echo ""

# 1. Stripe API Key para Development
echo "1️⃣ Configurando Stripe API Key de DESARROLLO..."
echo "   💡 Ve a: https://dashboard.stripe.com/test/apikeys"
echo "   📋 Copia tu 'Secret key' de TEST (empieza con 'sk_test_')"
echo ""
read -p "🔑 Ingresa tu Stripe API Key de TEST: " stripe_api_key

if [[ ! $stripe_api_key =~ ^sk_test_ ]]; then
    echo "⚠️  Advertencia: La clave no parece ser de TEST (no empieza con 'sk_test_')"
    read -p "¿Continuar de todos modos? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "❌ Cancelado por el usuario"
        exit 1
    fi
fi

# Crear entrada para Stripe API (Development)
if op item get "NestJS Stripe API" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Stripe API" "Secret Key[password]"="$stripe_api_key"
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "API Credential" \
        --title "NestJS Stripe API" \
        "Secret Key[password]"="$stripe_api_key" \
        --tags "nestjs,stripe,development"
fi

echo "✅ Stripe API Key configurada"
echo ""

# 2. Stripe Webhook Secret para Development
echo "2️⃣ Configurando Stripe Webhook Secret de DESARROLLO..."
echo "   💡 Si usas 'stripe listen', el secret se genera automáticamente"
echo "   📋 Para webhooks locales, usa: whsec_..."
echo ""
read -p "🔑 Ingresa tu Stripe Webhook Secret de DESARROLLO: " webhook_secret

# Crear entrada para Stripe Webhook (Development)
if op item get "NestJS Stripe Webhook" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Stripe Webhook" "Webhook Secret[password]"="$webhook_secret"
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "API Credential" \
        --title "NestJS Stripe Webhook" \
        "Webhook Secret[password]"="$webhook_secret" \
        --tags "nestjs,stripe,webhook,development"
fi

echo "✅ Stripe Webhook Secret configurado"
echo ""

# 3. Bases de datos de Notion para Development
echo "3️⃣ Configurando bases de datos de Notion para DESARROLLO..."
echo "   💡 Usa bases de datos SEPARADAS para desarrollo"
echo "   📋 Formato: 32 caracteres hexadecimales"
echo ""

read -p "🗄️  Database ID de CLIENTES (development): " clients_db_dev
read -p "💰 Database ID de PAGOS (development): " payments_db_dev
<<<<<<< HEAD
=======
read -p "📅 Database ID de CALENDARIO (development): " calendar_db_dev
>>>>>>> develop

# Crear entrada para Notion Databases (Development)
if op item get "NestJS Notion Databases" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Notion Databases" \
        "Clients Database ID[text]"="$clients_db_dev" \
<<<<<<< HEAD
        "Payments Database ID[text]"="$payments_db_dev"
=======
        "Payments Database ID[text]"="$payments_db_dev" \
        "Calendar Database ID[text]"="$calendar_db_dev"
>>>>>>> develop
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "Database" \
        --title "NestJS Notion Databases" \
        "Clients Database ID[text]"="$clients_db_dev" \
        "Payments Database ID[text]"="$payments_db_dev" \
<<<<<<< HEAD
=======
        "Calendar Database ID[text]"="$calendar_db_dev" \
>>>>>>> develop
        --tags "nestjs,notion,development"
fi

echo "✅ Bases de datos de Notion configuradas"
echo ""

# Verificación final
echo "🔍 Verificando configuración..."

# Test de lectura de variables
stripe_key=$(op item get "NestJS Stripe API" --field "Secret Key" --reveal 2>/dev/null || echo "ERROR")
webhook_secret=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal 2>/dev/null || echo "ERROR")
clients_db=$(op item get "NestJS Notion Databases" --field "Clients Database ID" 2>/dev/null || echo "ERROR")
payments_db=$(op item get "NestJS Notion Databases" --field "Payments Database ID" 2>/dev/null || echo "ERROR")
<<<<<<< HEAD

if [[ $stripe_key == "ERROR" || $webhook_secret == "ERROR" || $clients_db == "ERROR" || $payments_db == "ERROR" ]]; then
=======
calendar_db=$(op item get "NestJS Notion Databases" --field "Calendar Database ID" 2>/dev/null || echo "ERROR")

if [[ $stripe_key == "ERROR" || $webhook_secret == "ERROR" || $clients_db == "ERROR" || $payments_db == "ERROR" || $calendar_db == "ERROR" ]]; then
>>>>>>> develop
    echo "❌ Error en la verificación. Algunas credenciales no se pudieron leer."
    exit 1
fi

echo "✅ Todas las credenciales de DESARROLLO están configuradas correctamente"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Configura las bases de datos en Notion según docs/NOTION-SETUP.md"
echo "   2. Ejecuta: pnpm run dev (para desarrollo local)"
echo "   3. Para configurar PRODUCCIÓN: ./scripts/setup-1password-prod.sh"
echo "" 