#!/bin/bash

# 🏭 Script para configurar credenciales de PRODUCCIÓN en 1Password
# Separa las credenciales de test vs producción

set -e

echo "🏭 Configurando Credenciales de PRODUCCIÓN en 1Password"
echo "======================================================"

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
echo "📝 Vamos a crear entradas SEPARADAS para producción:"
echo "   1. NestJS Stripe API PROD"
echo "   2. NestJS Stripe Webhook PROD"
echo "   3. (Notion se mantiene igual - funciona para ambos ambientes)"
echo ""

# Función para leer input de forma segura
read_secret() {
    local prompt="$1"
    local varname="$2"
    local prefix="$3"
    
    while true; do
        echo ""
        echo "$prompt"
        echo "💡 Opciones:"
        echo "   1. Escribir/pegar directamente"
        echo "   2. Saltar por ahora"
        echo -n "Selecciona una opción (1-2): "
        read choice
        
        case $choice in
            1)
                echo -n "Pega tu clave de PRODUCCIÓN aquí: "
                read value
                if [ -n "$value" ] && [[ "$value" == $prefix* ]]; then
                    eval "$varname='$value'"
                    echo "✅ Clave de producción válida recibida"
                    break
                elif [ -n "$value" ]; then
                    echo "⚠️  Advertencia: La clave no tiene el prefijo esperado ($prefix)"
                    echo -n "¿Continuar de todas formas? (y/N): "
                    read confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        eval "$varname='$value'"
                        break
                    fi
                else
                    echo "❌ Valor vacío, intenta de nuevo"
                fi
                ;;
            2)
                echo "⏭️  Saltando configuración de esta clave"
                eval "$varname=''"
                break
                ;;
            *)
                echo "❌ Opción no válida"
                ;;
        esac
    done
}

# Función para crear entrada en 1Password
create_item() {
    local title="$1"
    local username="$2"
    shift 2
    local fields=("$@")
    
    echo "🔐 Creando entrada: $title"
    
    local cmd="op item create --category=login --title='$title'"
    
    if [ -n "$username" ]; then
        cmd="$cmd --username='$username'"
    fi
    
    for field in "${fields[@]}"; do
        if [[ $field =~ ^([^=]+)=(.+)$ ]]; then
            local field_def="${BASH_REMATCH[1]}"
            local field_value="${BASH_REMATCH[2]}"
            cmd="$cmd '${field_def}'='${field_value}'"
        fi
    done
    
    local output
    local exit_code
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Entrada '$title' creada exitosamente"
        return 0
    else
        echo "❌ Error creando entrada '$title'"
        if echo "$output" | grep -i "already exists" > /dev/null; then
            echo -n "💡 La entrada ya existe. ¿Quieres actualizarla? (y/N): "
            read confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                local update_cmd=$(echo "$cmd" | sed 's/create/edit/')
                output=$(eval "$update_cmd" 2>&1)
                exit_code=$?
                if [ $exit_code -eq 0 ]; then
                    echo "✅ Entrada '$title' actualizada exitosamente"
                    return 0
                else
                    echo "❌ Error actualizando entrada: $output"
                    return 1
                fi
            fi
        fi
        return 1
    fi
}

echo "1️⃣ Configurando Stripe API Key de PRODUCCIÓN"
echo "=============================================="
echo "⚠️  IMPORTANTE: Usa tu clave LIVE (sk_live_...) no TEST (sk_test_...)"
read_secret "Stripe SECRET KEY de PRODUCCIÓN (sk_live_...)" STRIPE_SECRET_KEY_PROD "sk_live_"

if [ -n "$STRIPE_SECRET_KEY_PROD" ]; then
    if ! create_item "NestJS Stripe API PROD" "" "Secret Key[password]=$STRIPE_SECRET_KEY_PROD"; then
        echo "⚠️  Continuando con la siguiente configuración..."
    fi
else
    echo "⏭️  Saltando configuración de Stripe API Key de producción"
fi

echo ""
echo "2️⃣ Configurando Stripe Webhook de PRODUCCIÓN"
echo "=============================================="
echo "ℹ️  Debes crear el webhook en Stripe Dashboard DESPUÉS del deployment"
echo "📍 URL será: https://nestjs-stripe-notion.fly.dev/webhook/stripe"
read_secret "Stripe Webhook Secret de PRODUCCIÓN (whsec_...)" STRIPE_WEBHOOK_SECRET_PROD "whsec_"

if [ -n "$STRIPE_WEBHOOK_SECRET_PROD" ]; then
    if ! create_item "NestJS Stripe Webhook PROD" "" "Webhook Secret[password]=$STRIPE_WEBHOOK_SECRET_PROD"; then
        echo "⚠️  Error creando entrada de webhook"
    fi
else
    echo "⏭️  Saltando configuración de Stripe Webhook de producción"
    echo "💡 Puedes configurarlo después del deployment"
fi

echo ""
echo "🎉 ¡Configuración de PRODUCCIÓN completada!"
echo "============================================="
echo ""
echo "📋 Entradas creadas en 1Password:"
echo "   🧪 TEST:"
echo "      - NestJS Stripe API"
echo "      - NestJS Stripe Webhook" 
echo "   🏭 PRODUCCIÓN:"
echo "      - NestJS Stripe API PROD"
echo "      - NestJS Stripe Webhook PROD"
echo "   📚 COMPARTIDO:"
echo "      - NestJS Notion Integration"
echo "      - NestJS Notion Databases"
echo ""
echo "🔗 Próximos pasos:"
echo "   1. Ejecutar: pnpm run deploy"
echo "   2. Configurar webhook en Stripe Dashboard con URL de producción"
echo "   3. Actualizar webhook secret de producción en 1Password" 