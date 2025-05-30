#!/bin/bash

# 🧪 Script para probar webhooks en desarrollo local
# Configura Stripe Listen con el webhook secret correcto

set -e

echo "🧪 Configurando webhooks para desarrollo local"
echo "=============================================="

# Verificar que Stripe CLI esté instalado
if ! command -v stripe &> /dev/null; then
    echo "❌ Error: Stripe CLI no está instalado"
    echo "💡 Instalar con: brew install stripe/stripe-cli/stripe"
    exit 1
fi

# Verificar que esté autenticado
if ! stripe config --list &> /dev/null; then
    echo "❌ Error: No estás autenticado en Stripe CLI"
    echo "🔑 Ejecuta: stripe login"
    exit 1
fi

echo ""
echo "🔍 Verificando que la aplicación esté corriendo..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Aplicación corriendo en http://localhost:3000"
else
    echo "❌ La aplicación no está corriendo en puerto 3000"
    echo "🚀 Ejecuta: pnpm run docker:1password:dev"
    exit 1
fi

echo ""
echo "🔧 Configurando webhook secret para desarrollo..."

# Obtener el webhook secret de Stripe listen
echo "📡 Iniciando Stripe listen para obtener webhook secret..."
stripe listen --print-secret --forward-to localhost:3000/webhook/stripe > temp_webhook_output.txt 2>&1 &
LISTEN_PID=$!

# Esperar un poco para que se genere el secret
sleep 3

# Extraer el webhook secret del output
WEBHOOK_SECRET=$(grep -o "whsec_[a-zA-Z0-9_]*" temp_webhook_output.txt | head -1)

if [ -z "$WEBHOOK_SECRET" ]; then
    echo "❌ No se pudo obtener el webhook secret"
    kill $LISTEN_PID 2>/dev/null || true
    rm -f temp_webhook_output.txt
    exit 1
fi

echo "🔑 Webhook secret obtenido: ${WEBHOOK_SECRET:0:10}..."

# Actualizar el webhook secret en 1Password
echo "🔐 Actualizando webhook secret en 1Password..."
if op item edit "NestJS Stripe Webhook" "Webhook Secret[password]"="$WEBHOOK_SECRET" > /dev/null 2>&1; then
    echo "✅ Webhook secret actualizado en 1Password"
else
    echo "❌ Error actualizando 1Password, intentando crear nueva entrada..."
    if op item create --category=login --title="NestJS Stripe Webhook" "Webhook Secret[password]"="$WEBHOOK_SECRET" > /dev/null 2>&1; then
        echo "✅ Nueva entrada de webhook creada en 1Password"
    else
        echo "❌ Error crítico: No se pudo actualizar 1Password"
        kill $LISTEN_PID 2>/dev/null || true
        rm -f temp_webhook_output.txt
        exit 1
    fi
fi

# Reiniciar el contenedor Docker para cargar la nueva variable desde 1Password
echo ""
echo "🔄 Reiniciando aplicación Docker para cargar nuevo webhook secret..."
echo "⚠️  Deteniendo Docker actual y reiniciando con 1Password..."
docker-compose -f docker-compose.dev.yml down > /dev/null 2>&1 || true
echo "🚀 Iniciando Docker con variables de 1Password..."
./scripts/docker-1password.sh dev > /dev/null 2>&1 &
DOCKER_PID=$!

# Esperar que se reinicie
echo "⏳ Esperando que la aplicación se reinicie..."
sleep 5

# Verificar que la aplicación esté disponible
attempts=0
max_attempts=10
while [ $attempts -lt $max_attempts ]; do
    if curl -s http://localhost:3000/health > /dev/null; then
        echo "✅ Aplicación reiniciada correctamente"
        break
    fi
    attempts=$((attempts + 1))
    echo "⏳ Esperando... (intento $attempts/$max_attempts)"
    sleep 2
done

if [ $attempts -eq $max_attempts ]; then
    echo "❌ La aplicación no se pudo reiniciar"
    kill $LISTEN_PID 2>/dev/null || true
    rm -f temp_webhook_output.txt
    exit 1
fi

# Limpiar archivos temporales
rm -f temp_webhook_output.txt

echo ""
echo "🎉 ¡Configuración completada!"
echo "=============================="
echo ""
echo "📡 Stripe listen está corriendo en background (PID: $LISTEN_PID)"
echo "🔗 Webhooks se reenvían a: http://localhost:3000/webhook/stripe"
echo "🔑 Webhook secret: ${WEBHOOK_SECRET:0:15}..."
echo ""
echo "🧪 Ahora puedes probar webhooks:"
echo "   stripe trigger payment_intent.succeeded"
echo "   stripe trigger payment_intent.succeeded --override payment_intent:amount=5000"
echo ""
echo "📊 Ver logs de la aplicación:"
echo "   docker logs nestjs-stripe-dev --follow"
echo ""
echo "🛑 Para detener Stripe listen:"
echo "   kill $LISTEN_PID"
echo ""

# Función para cleanup al salir
cleanup() {
    echo ""
    echo "🧹 Limpiando procesos..."
    kill $LISTEN_PID 2>/dev/null || true
    echo "✅ Stripe listen detenido"
    if [ ! -z "$DOCKER_PID" ]; then
        kill $DOCKER_PID 2>/dev/null || true
        echo "✅ Proceso Docker detenido"
    fi
}

# Registrar cleanup function
trap cleanup EXIT

echo "💡 Presiona Ctrl+C para detener Stripe listen y salir"
echo "👂 Escuchando webhooks..."

# Mantener el script corriendo y mostrar logs del listen
wait $LISTEN_PID 