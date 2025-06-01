#!/bin/bash

# 🎯 Script para testear webhooks de Stripe
# Envía eventos simulados al webhook para probar la integración

set -e

# Colores
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

# URLs de webhook
WEBHOOK_DEV="https://nestjs-stripe-notion-dev.fly.dev/webhook/stripe/test"
WEBHOOK_PROD="https://nestjs-stripe-notion.fly.dev/webhook/stripe"

# Función para mostrar ayuda
show_help() {
    print_color $CYAN "🎯 Tester de Webhooks Stripe"
    print_color $CYAN "============================"
    echo ""
    print_color $WHITE "Uso: $0 [AMBIENTE] [EVENTO]"
    echo ""
    print_color $YELLOW "AMBIENTES:"
    print_color $WHITE "  dev     Webhook de desarrollo"
    print_color $WHITE "  prod    Webhook de producción"
    echo ""
    print_color $YELLOW "EVENTOS:"
    print_color $WHITE "  payment   Simular pago exitoso"
    print_color $WHITE "  customer  Simular nuevo cliente"
    print_color $WHITE "  custom    Enviar evento personalizado"
    echo ""
    print_color $YELLOW "EJEMPLOS:"
    print_color $WHITE "  $0 dev payment"
    print_color $WHITE "  $0 prod customer"
}

# Payload simulado de payment_intent.succeeded
create_payment_payload() {
    cat << 'EOF'
{
  "id": "evt_test_webhook",
  "object": "event",
  "api_version": "2020-08-27",
  "created": 1609459200,
  "data": {
    "object": {
      "id": "pi_test_payment_intent",
      "object": "payment_intent",
      "amount": 2500,
      "amount_received": 2500,
      "currency": "usd",
      "status": "succeeded",
      "customer": {
        "id": "cus_test_customer",
        "object": "customer",
        "email": "roberto.test@example.com",
        "name": "Roberto Test"
      },
      "metadata": {
        "customer_name": "Roberto Test",
        "customer_email": "roberto.test@example.com"
      },
      "payment_method": {
        "id": "pm_test_card",
        "object": "payment_method",
        "type": "card"
      }
    }
  },
  "livemode": false,
  "pending_webhooks": 1,
  "request": {
    "id": "req_test_request",
    "idempotency_key": null
  },
  "type": "payment_intent.succeeded"
}
EOF
}

# Payload simulado de customer.created
create_customer_payload() {
    cat << 'EOF'
{
  "id": "evt_test_customer",
  "object": "event",
  "api_version": "2020-08-27",
  "created": 1609459200,
  "data": {
    "object": {
      "id": "cus_test_new_customer",
      "object": "customer",
      "email": "nuevocliente@example.com",
      "name": "Cliente Nuevo Test",
      "phone": "+1234567890",
      "created": 1609459200
    }
  },
  "livemode": false,
  "pending_webhooks": 1,
  "request": {
    "id": "req_test_customer",
    "idempotency_key": null
  },
  "type": "customer.created"
}
EOF
}

# Función para enviar webhook
send_webhook() {
    local webhook_url="$1"
    local payload="$2"
    local event_type="$3"
    
    print_color $BLUE "🚀 Enviando evento '$event_type' a:"
    print_color $WHITE "   $webhook_url"
    echo ""
    
    # Guardar payload en archivo temporal
    local payload_file="/tmp/webhook_payload_$$"
    echo "$payload" > "$payload_file"
    
    # Enviar webhook con headers apropiados
    local response_file="/tmp/webhook_response_$$"
    local status_code
    
    status_code=$(curl -s -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "User-Agent: Stripe/1.0 (+https://stripe.com/docs/webhooks)" \
        -d @"$payload_file" \
        "$webhook_url" \
        -o "$response_file" 2>/dev/null || echo "000")
    
    # Mostrar resultado
    if [ "$status_code" = "200" ] || [ "$status_code" = "201" ] || [ "$status_code" = "204" ]; then
        print_color $GREEN "✅ Evento enviado exitosamente ($status_code)"
        echo ""
        print_color $BLUE "📄 Respuesta del servidor:"
        cat "$response_file" | head -c 500
        echo ""
    else
        print_color $RED "❌ Error enviando evento ($status_code)"
        echo ""
        print_color $YELLOW "📄 Respuesta del servidor:"
        cat "$response_file" | head -c 500
        echo ""
    fi
    
    # Cleanup
    rm -f "$payload_file" "$response_file"
    
    echo ""
    print_color $CYAN "💡 Para ver los logs en tiempo real:"
    if [[ $webhook_url == *"dev"* ]]; then
        print_color $WHITE "   flyctl logs --app nestjs-stripe-notion-dev -f"
    else
        print_color $WHITE "   flyctl logs --app nestjs-stripe-notion -f"
    fi
}

# Función principal
main() {
    local environment="$1"
    local event_type="$2"
    
    if [ -z "$environment" ] || [ -z "$event_type" ]; then
        show_help
        exit 1
    fi
    
    # Determinar webhook URL
    local webhook_url=""
    case $environment in
        dev|development)
            webhook_url="$WEBHOOK_DEV"
            print_color $CYAN "🧪 Testeando webhook de DESARROLLO"
            ;;
        prod|production)
            webhook_url="$WEBHOOK_PROD"
            print_color $CYAN "🏭 Testeando webhook de PRODUCCIÓN"
            ;;
        *)
            print_color $RED "❌ Ambiente no válido: $environment"
            show_help
            exit 1
            ;;
    esac
    
    # Generar payload según el tipo de evento
    local payload=""
    case $event_type in
        payment|pay)
            payload=$(create_payment_payload)
            event_type="payment_intent.succeeded"
            ;;
        customer|cust)
            payload=$(create_customer_payload)
            event_type="customer.created"
            ;;
        custom)
            print_color $YELLOW "📝 Ingresa el payload JSON personalizado:"
            print_color $WHITE "   (Presiona Ctrl+D cuando termines)"
            payload=$(cat)
            event_type="custom"
            ;;
        *)
            print_color $RED "❌ Tipo de evento no válido: $event_type"
            show_help
            exit 1
            ;;
    esac
    
    # Enviar webhook
    send_webhook "$webhook_url" "$payload" "$event_type"
}

# Ejecutar
main "$@" 