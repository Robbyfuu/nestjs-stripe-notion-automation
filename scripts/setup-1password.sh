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
    local prefix="$3"
    
    while true; do
        echo ""
        echo "$prompt"
        echo "💡 Opciones:"
        echo "   1. Escribir/pegar directamente"
        echo "   2. Leer desde archivo temporal"
        echo "   3. Saltar por ahora"
        echo -n "Selecciona una opción (1-3): "
        read choice
        
        case $choice in
            1)
                echo -n "Pega tu clave aquí: "
                # Usar read normal para permitir pegar texto largo
                read value
                if [ -n "$value" ] && [[ "$value" == $prefix* ]]; then
                    eval "$varname='$value'"
                    echo "✅ Clave válida recibida"
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
                echo "📝 Crea un archivo temporal con tu clave:"
                temp_file="/tmp/temp_secret_$(date +%s)"
                echo "   echo 'tu_clave_aqui' > $temp_file"
                echo ""
                echo "Presiona Enter cuando hayas creado el archivo..."
                read
                
                if [ -f "$temp_file" ]; then
                    value=$(cat "$temp_file" | tr -d '\n' | tr -d ' ')
                    rm -f "$temp_file"
                    if [ -n "$value" ] && [[ "$value" == $prefix* ]]; then
                        eval "$varname='$value'"
                        echo "✅ Clave leída desde archivo"
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
                        echo "❌ Archivo vacío o no válido"
                    fi
                else
                    echo "❌ Archivo no encontrado"
                fi
                ;;
            3)
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
read_secret "Stripe Secret Key (sk_test_... o sk_live_...)" STRIPE_SECRET_KEY "sk_"

if [ -n "$STRIPE_SECRET_KEY" ]; then
    create_item "NestJS Stripe API" "" "Secret Key[password]=$STRIPE_SECRET_KEY"
fi

echo ""
echo "2️⃣ Configurando Stripe Webhook"
echo "==============================="
read_secret "Stripe Webhook Secret (whsec_...)" STRIPE_WEBHOOK_SECRET "whsec_"

if [ -n "$STRIPE_WEBHOOK_SECRET" ]; then
    create_item "NestJS Stripe Webhook" "" "Webhook Secret[password]=$STRIPE_WEBHOOK_SECRET"
fi

echo ""
echo "3️⃣ Configurando Notion Integration"
echo "==================================="
read_secret "Notion Integration Secret (secret_...)" NOTION_SECRET "secret_"

if [ -n "$NOTION_SECRET" ]; then
    create_item "NestJS Notion Integration" "" "Integration Secret[password]=$NOTION_SECRET"
fi

echo ""
echo "4️⃣ Configurando Notion Databases"
echo "================================="

# Función para leer IDs de base de datos
read_database_id() {
    local prompt="$1"
    local varname="$2"
    
    while true; do
        echo ""
        echo "$prompt"
        echo "💡 El ID está en la URL: https://notion.so/workspace/DATABASE_ID?v=..."
        echo "💡 Debe tener 32 caracteres (sin guiones)"
        echo ""
        echo "Opciones:"
        echo "   1. Escribir/pegar ID"
        echo "   2. Pegar URL completa (extraeré el ID)"
        echo "   3. Saltar por ahora"
        echo -n "Selecciona una opción (1-3): "
        read choice
        
        case $choice in
            1)
                echo -n "Pega el Database ID: "
                read value
                # Limpiar espacios y guiones
                value=$(echo "$value" | tr -d ' ' | tr -d '-')
                if [ ${#value} -eq 32 ] && [[ $value =~ ^[a-zA-Z0-9]+$ ]]; then
                    eval "$varname='$value'"
                    echo "✅ ID válido recibido"
                    break
                elif [ -n "$value" ]; then
                    echo "❌ ID inválido. Debe tener 32 caracteres alfanuméricos"
                    echo "   Recibido: '$value' (${#value} caracteres)"
                else
                    echo "❌ Valor vacío"
                fi
                ;;
            2)
                echo -n "Pega la URL completa de Notion: "
                read url
                # Extraer ID de la URL
                if [[ $url =~ ([a-zA-Z0-9]{32}) ]]; then
                    value="${BASH_REMATCH[1]}"
                    eval "$varname='$value'"
                    echo "✅ ID extraído de URL: $value"
                    break
                else
                    echo "❌ No se pudo extraer el ID de la URL"
                fi
                ;;
            3)
                echo "⏭️  Saltando configuración de este ID"
                eval "$varname=''"
                break
                ;;
            *)
                echo "❌ Opción no válida"
                ;;
        esac
    done
}

read_database_id "Notion Payments Database ID" NOTION_PAYMENTS_DB_ID
read_database_id "Notion Clients Database ID" NOTION_CLIENTS_DB_ID

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