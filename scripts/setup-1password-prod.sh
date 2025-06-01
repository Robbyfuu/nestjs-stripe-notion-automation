#!/bin/bash

# 🔐 Script para configurar credenciales de PRODUCCIÓN en 1Password
# Este script configura las entradas específicas para el ambiente de producción

set -e

echo "🔐 Configurando credenciales de PRODUCCIÓN en 1Password..."
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

echo "⚠️  IMPORTANTE: Estás configurando credenciales de PRODUCCIÓN"
echo "💡 Usa claves REALES de Stripe (empiezan con 'sk_live_')"
echo "🔒 Asegúrate de que sean las credenciales correctas"
echo ""

read -p "¿Confirmas que quieres configurar PRODUCCIÓN? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "❌ Cancelado por el usuario"
    exit 1
fi

echo ""

# 1. Stripe API Key para Production
echo "1️⃣ Configurando Stripe API Key de PRODUCCIÓN..."
echo "   💡 Ve a: https://dashboard.stripe.com/apikeys"
echo "   📋 Copia tu 'Secret key' de LIVE (empieza con 'sk_live_')"
echo ""
read -p "🔑 Ingresa tu Stripe API Key de PRODUCCIÓN: " stripe_api_key

if [[ ! $stripe_api_key =~ ^sk_live_ ]]; then
    echo "⚠️  Advertencia: La clave no parece ser de PRODUCCIÓN (no empieza con 'sk_live_')"
    read -p "¿Continuar de todos modos? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "❌ Cancelado por el usuario"
        exit 1
    fi
fi

# Crear entrada para Stripe API (Production)
if op item get "NestJS Stripe API PROD" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Stripe API PROD" "Secret Key[password]"="$stripe_api_key"
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "API Credential" \
        --title "NestJS Stripe API PROD" \
        "Secret Key[password]"="$stripe_api_key" \
        --tags "nestjs,stripe,production"
fi

echo "✅ Stripe API Key de PRODUCCIÓN configurada"
echo ""

# 2. Stripe Webhook Secret para Production
echo "2️⃣ Configurando Stripe Webhook Secret de PRODUCCIÓN..."
echo "   💡 Ve a: https://dashboard.stripe.com/webhooks"
echo "   📋 Configura el endpoint: https://tu-app.fly.dev/webhook/stripe"
echo "   🔑 Copia el 'Signing secret' (empieza con 'whsec_')"
echo ""
read -p "🔑 Ingresa tu Stripe Webhook Secret de PRODUCCIÓN: " webhook_secret

# Crear entrada para Stripe Webhook (Production)
if op item get "NestJS Stripe Webhook PROD" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Stripe Webhook PROD" "Webhook Secret[password]"="$webhook_secret"
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "API Credential" \
        --title "NestJS Stripe Webhook PROD" \
        "Webhook Secret[password]"="$webhook_secret" \
        --tags "nestjs,stripe,webhook,production"
fi

echo "✅ Stripe Webhook Secret de PRODUCCIÓN configurado"
echo ""

# 3. Bases de datos de Notion para Production
echo "3️⃣ Configurando bases de datos de Notion para PRODUCCIÓN..."
echo "   💡 Usa bases de datos SEPARADAS para producción"
echo "   📋 Formato: 32 caracteres hexadecimales"
echo ""

read -p "🗄️  Database ID de CLIENTES (production): " clients_db_prod
read -p "💰 Database ID de PAGOS (production): " payments_db_prod
<<<<<<< HEAD
=======
read -p "📅 Database ID de CALENDARIO (production): " calendar_db_prod
>>>>>>> develop

# Crear entrada para Notion Databases (Production)
if op item get "NestJS Notion Databases PROD" &>/dev/null; then
    echo "✏️  Actualizando entrada existente..."
    op item edit "NestJS Notion Databases PROD" \
        "Clients Database ID[text]"="$clients_db_prod" \
<<<<<<< HEAD
        "Payments Database ID[text]"="$payments_db_prod"
=======
        "Payments Database ID[text]"="$payments_db_prod" \
        "Calendar Database ID[text]"="$calendar_db_prod"
>>>>>>> develop
else
    echo "🆕 Creando nueva entrada..."
    op item create \
        --category "Database" \
        --title "NestJS Notion Databases PROD" \
        "Clients Database ID[text]"="$clients_db_prod" \
        "Payments Database ID[text]"="$payments_db_prod" \
<<<<<<< HEAD
=======
        "Calendar Database ID[text]"="$calendar_db_prod" \
>>>>>>> develop
        --tags "nestjs,notion,production"
fi

echo "✅ Bases de datos de Notion de PRODUCCIÓN configuradas"
echo ""

# Verificación final
echo "🔍 Verificando configuración de PRODUCCIÓN..."

# Test de lectura de variables
stripe_key=$(op item get "NestJS Stripe API PROD" --field "Secret Key" --reveal 2>/dev/null || echo "ERROR")
webhook_secret=$(op item get "NestJS Stripe Webhook PROD" --field "Webhook Secret" --reveal 2>/dev/null || echo "ERROR")
clients_db=$(op item get "NestJS Notion Databases PROD" --field "Clients Database ID" 2>/dev/null || echo "ERROR")
payments_db=$(op item get "NestJS Notion Databases PROD" --field "Payments Database ID" 2>/dev/null || echo "ERROR")
<<<<<<< HEAD

if [[ $stripe_key == "ERROR" || $webhook_secret == "ERROR" || $clients_db == "ERROR" || $payments_db == "ERROR" ]]; then
=======
calendar_db=$(op item get "NestJS Notion Databases PROD" --field "Calendar Database ID" 2>/dev/null || echo "ERROR")

if [[ $stripe_key == "ERROR" || $webhook_secret == "ERROR" || $clients_db == "ERROR" || $payments_db == "ERROR" || $calendar_db == "ERROR" ]]; then
>>>>>>> develop
    echo "❌ Error en la verificación. Algunas credenciales no se pudieron leer."
    exit 1
fi

echo "✅ Todas las credenciales de PRODUCCIÓN están configuradas correctamente"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Configura las bases de datos de producción en Notion"
echo "   2. Configura webhook en Stripe Dashboard apuntando a tu app de Fly.io"
echo "   3. Haz push a 'main' para deployment automático"
echo ""
echo "🚨 RECORDATORIO: Estas son credenciales de PRODUCCIÓN - manéjalas con cuidado" 