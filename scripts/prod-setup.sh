#!/bin/bash

# 🏭 Script para configurar y ejecutar en producción
# Incluye verificaciones de seguridad y configuración optimizada

set -e

echo "🏭 Configuración de Producción - NestJS Stripe Notion"
echo "===================================================="

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

echo "🔍 Verificando credenciales de producción..."

# Verificar credenciales críticas
missing_vars=()

if ! op item get "NestJS Stripe API" --field "Secret Key" --reveal &> /dev/null; then
    missing_vars+=("STRIPE_SECRET_KEY")
fi

if ! op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal &> /dev/null; then
    missing_vars+=("STRIPE_WEBHOOK_SECRET")
fi

if ! op item get "NestJS Notion Integration" --field "Integration Secret" --reveal &> /dev/null; then
    missing_vars+=("NOTION_SECRET")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Credenciales faltantes para producción:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "💡 Ejecuta el script de configuración: pnpm run setup"
    exit 1
fi

echo "✅ Credenciales verificadas"

# Verificar que tengamos un webhook secret de producción real
webhook_secret=$(op item get "NestJS Stripe Webhook" --field "Webhook Secret" --reveal)
if [[ $webhook_secret == whsec_9a07* ]]; then
    echo "⚠️  ADVERTENCIA: Estás usando un webhook secret de desarrollo"
    echo "🔗 Para producción, configura un webhook real en:"
    echo "   https://dashboard.stripe.com/webhooks"
    echo ""
    read -p "¿Continuar de todas formas? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ Cancelado. Configura el webhook de producción primero."
        exit 1
    fi
fi

# Verificar dominio de producción
echo ""
echo "🌐 ¿En qué dominio se ejecutará la aplicación?"
echo "💡 Ejemplo: https://api.tuempresa.com"
read -p "Dominio (presiona Enter para localhost): " domain
domain=${domain:-"http://localhost:3000"}

# Crear directorio de logs
echo "📁 Creando directorio de logs..."
mkdir -p logs

# Verificar que Docker esté corriendo
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker no está corriendo"
    echo "💡 Inicia Docker Desktop y vuelve a intentar"
    exit 1
fi

echo ""
echo "🚀 Iniciando aplicación en modo producción..."
./scripts/docker-1password.sh prod

echo ""
echo "⏳ Esperando que la aplicación esté lista..."
sleep 15

# Verificar que la aplicación esté funcionando
max_attempts=10
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s "${domain}/health" > /dev/null; then
        echo "✅ Aplicación lista y funcionando"
        echo ""
        echo "🎉 ¡Producción configurada exitosamente!"
        echo "=================================="
        echo ""
        echo "📊 Información de la aplicación:"
        echo "   URL: ${domain}"
        echo "   Webhook: ${domain}/webhook/stripe"
        echo "   Health: ${domain}/health"
        echo ""
        echo "📋 Comandos útiles:"
        echo "   docker-compose logs -f nestjs-stripe    # Ver logs"
        echo "   docker-compose down                      # Detener"
        echo "   docker-compose restart nestjs-stripe    # Reiniciar"
        echo ""
        echo "🔗 No olvides configurar el webhook en Stripe Dashboard:"
        echo "   URL: ${domain}/webhook/stripe"
        echo "   Eventos: payment_intent.succeeded"
        break
    fi
    
    attempt=$((attempt + 1))
    echo "⏳ Intento $attempt/$max_attempts..."
    sleep 3
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ La aplicación no respondió después de $max_attempts intentos"
    echo "📊 Ver logs: docker-compose logs nestjs-stripe"
    exit 1
fi 