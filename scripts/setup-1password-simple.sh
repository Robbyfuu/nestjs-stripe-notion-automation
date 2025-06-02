#!/bin/bash

# 🔧 Script Interactivo Simple para gestionar variables de entorno en 1Password
# Compatible con Bash 3.x (macOS default)

set -e

# Colores para mejor UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Verificar 1Password CLI
check_1password() {
    if ! command -v op &> /dev/null; then
        print_color $RED "❌ Error: 1Password CLI no está instalado"
        print_color $YELLOW "💡 Instalar con: brew install --cask 1password/tap/1password-cli"
        exit 1
    fi

    if ! op account list &> /dev/null; then
        print_color $YELLOW "🔑 Iniciando sesión en 1Password..."
        eval $(op signin)
    fi
}

# Función para mostrar encabezado
show_header() {
    clear
    print_color $CYAN "🔧 Gestor Interactivo de Variables de Entorno"
    print_color $CYAN "=============================================="
    print_color $WHITE "NestJS Stripe Notion WhatsApp Automation"
    echo ""
}

# Función para extraer ID de URL de Notion
extract_notion_id() {
    local url="$1"
    # Extraer ID de diferentes formatos de URL de Notion (exactamente 32 caracteres)
    if [[ $url =~ ([0-9a-f]{32})([^0-9a-f]|$) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    elif [[ $url =~ ([0-9A-F]{32})([^0-9A-F]|$) ]]; then
        # Convertir a minúsculas si está en mayúsculas
        echo "${BASH_REMATCH[1],,}"
        return 0
    else
        return 1
    fi
}

# Función para leer secretos/valores
read_secret() {
    local prompt="$1"
    local prefix="$2"
    local field_type="$3"
    local value=""
    
    echo ""
    print_color $YELLOW "$prompt"
    echo ""
    
    # Si es database_id, mostrar opciones especiales
    if [ "$field_type" = "database_id" ]; then
        # Mostrar opciones en stderr para no contaminar el return value
        echo "" >&2
        print_color $CYAN "💡 Opciones para ingresar:" >&2
        print_color $WHITE "   1. Pegar URL completa de Notion (recomendado)" >&2
        print_color $WHITE "   2. Ingresar ID directo (32 caracteres)" >&2
        echo "" >&2
        echo -n "¿Cómo quieres ingresar el dato? (1/2): " >&2
        read input_method < /dev/tty
        
        case $input_method in
            1)
                echo "" >&2
                print_color $CYAN "📋 Pega la URL completa de tu base de datos de Notion:" >&2
                print_color $WHITE "   Ejemplo: https://www.notion.so/workspace/titulo-database-abc123...def456" >&2
                echo -n "🔗 URL: " >&2
                read url_input < /dev/tty
                
                local extracted_id
                extracted_id=$(extract_notion_id "$url_input")
                if [ $? -eq 0 ] && [ -n "$extracted_id" ]; then
                    value="$extracted_id"
                    print_color $GREEN "✅ ID extraído: ${value:0:8}...${value: -8}" >&2
                else
                    print_color $RED "❌ No se pudo extraer el ID de la URL" >&2
                    print_color $YELLOW "💡 Intenta con la opción 2 (ID directo)" >&2
                    return 1
                fi
                ;;
            2)
                echo "" >&2
                print_color $CYAN "🔑 Ingresa el ID de la base de datos:" >&2
                print_color $WHITE "   Formato: 32 caracteres alfanuméricos (abc123def456...)" >&2
                echo -n "🆔 ID: " >&2
                read direct_id < /dev/tty
                if [[ $direct_id =~ ^[0-9a-f]{32}$ ]]; then
                    value="$direct_id"
                    print_color $GREEN "✅ ID válido recibido" >&2
                else
                    print_color $RED "❌ Formato de ID inválido (debe ser 32 caracteres)" >&2
                    return 1
                fi
                ;;
            *)
                print_color $RED "❌ Opción no válida" >&2
                return 1
                ;;
        esac
    else
        # Para otros tipos de datos (API keys, secrets, etc.)
        if [[ $prompt == *"Secret Key"* ]]; then
            if [[ $prompt == *"PROD"* ]]; then
                print_color $BLUE "💡 Necesitas la clave de PRODUCCIÓN de Stripe"
                print_color $WHITE "   1. Ve a: https://dashboard.stripe.com/apikeys"
                print_color $WHITE "   2. Copia la 'Secret key' (empieza con 'sk_live_')"
            else
                print_color $BLUE "💡 Necesitas la clave de TEST de Stripe"
                print_color $WHITE "   1. Ve a: https://dashboard.stripe.com/test/apikeys"
                print_color $WHITE "   2. Copia la 'Secret key' (empieza con 'sk_test_')"
            fi
        elif [[ $prompt == *"Webhook Secret"* ]]; then
            if [[ $prompt == *"PROD"* ]]; then
                print_color $BLUE "💡 Necesitas el webhook secret de PRODUCCIÓN"
                print_color $WHITE "   1. Ve a: https://dashboard.stripe.com/webhooks"
                print_color $WHITE "   2. Selecciona tu endpoint de producción"
                print_color $WHITE "   3. Copia el 'Signing secret' (empieza con 'whsec_')"
            else
                print_color $BLUE "💡 Necesitas el webhook secret de DESARROLLO"
                print_color $WHITE "   1. Ve a: https://dashboard.stripe.com/test/webhooks"
                print_color $WHITE "   2. Selecciona tu endpoint de desarrollo"
                print_color $WHITE "   3. Copia el 'Signing secret' (empieza con 'whsec_')"
            fi
        elif [[ $prompt == *"Integration Secret"* ]]; then
            print_color $BLUE "💡 Necesitas el token de integración de Notion"
            print_color $WHITE "   1. Ve a: https://www.notion.so/my-integrations"
            print_color $WHITE "   2. Selecciona tu integración"
            print_color $WHITE "   3. Copia el 'Internal Integration Token' (empieza con 'secret_')"
        elif [[ $prompt == *"Twilio Account SID"* ]]; then
            print_color $BLUE "💡 Necesitas el Account SID de Twilio"
            print_color $WHITE "   1. Ve a: https://console.twilio.com/"
            print_color $WHITE "   2. En el Dashboard, encuentra 'Account Info'"
            print_color $WHITE "   3. Copia el 'Account SID' (empieza con 'AC')"
        elif [[ $prompt == *"Twilio Auth Token"* ]]; then
            print_color $BLUE "💡 Necesitas el Auth Token de Twilio"
            print_color $WHITE "   1. Ve a: https://console.twilio.com/"
            print_color $WHITE "   2. En el Dashboard, encuentra 'Account Info'"
            print_color $WHITE "   3. Copia el 'Auth Token' (haz clic en 'View' si está oculto)"
        elif [[ $prompt == *"Twilio WhatsApp From"* ]]; then
            print_color $BLUE "💡 Número de WhatsApp de Twilio"
            print_color $WHITE "   1. Ve a: https://console.twilio.com/"
            print_color $WHITE "   2. Ve a 'Develop > Messaging > Try it out > Send a WhatsApp message'"
            print_color $WHITE "   3. Usa el número del sandbox: +14155238886"
            print_color $YELLOW "   ⚠️  Para producción necesitas un número verificado"
        elif [[ $prompt == *"Meta WhatsApp Access Token"* ]]; then
            print_color $BLUE "💡 Access Token de Meta WhatsApp Business API"
            print_color $WHITE "   1. Ve a: https://developers.facebook.com/"
            print_color $WHITE "   2. Selecciona tu app > WhatsApp > API Setup"
            print_color $WHITE "   3. Copia el 'Temporary access token' o genera uno permanente"
        elif [[ $prompt == *"Meta WhatsApp Phone Number ID"* ]]; then
            print_color $BLUE "💡 Phone Number ID de Meta WhatsApp"
            print_color $WHITE "   1. Ve a: https://developers.facebook.com/"
            print_color $WHITE "   2. Selecciona tu app > WhatsApp > API Setup"
            print_color $WHITE "   3. Copia el 'Phone number ID' de tu número verificado"
        fi
        
        if [ -n "$prefix" ]; then
            print_color $CYAN "🔑 Debe empezar con: $prefix"
        fi
        echo -n "📝 Valor: "
        read value < /dev/tty
    fi
    
    # Validar prefijo si es necesario
    if [ -n "$prefix" ] && [[ ! "$value" =~ ^$prefix ]]; then
        print_color $YELLOW "⚠️  El valor no tiene el prefijo esperado ($prefix)" >&2
        echo -n "¿Continuar de todas formas? (y/N): " >&2
        read confirm < /dev/tty
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Solo retornar el valor limpio, sin colores ni mensajes adicionales
    echo "$value"
}

# Función para crear/actualizar variable
create_or_update_var() {
    local item_title="$1"
    local field_name="$2"
    local field_value="$3"
    local field_type_hint="$4"  # Nuevo parámetro opcional
    
    # Determinar tipo de campo
    local field_type="text"
    if [[ $field_name == *"Secret"* ]] || [[ $field_name == *"Key"* ]] || [[ $field_name == *"Token"* ]]; then
        field_type="password"
    elif [[ $field_type_hint == "database_id" ]] || [[ $field_name == *"Database ID"* ]]; then
        field_type="text"
    fi
    
    # Verificar si la entrada existe
    if op item get "$item_title" &>/dev/null; then
        print_color $BLUE "✏️  Actualizando entrada existente: $item_title" >&2
        if op item edit "$item_title" "${field_name}[${field_type}]"="$field_value" &>/dev/null; then
            print_color $GREEN "✅ Variable actualizada exitosamente" >&2
        else
            print_color $RED "❌ Error actualizando variable" >&2
            return 1
        fi
    else
        print_color $BLUE "🆕 Creando nueva entrada: $item_title" >&2
        local category="API Credential"
        if [[ $item_title == *"Database"* ]]; then
            category="Database"
        elif [[ $item_title == *"WhatsApp"* ]]; then
            category="API Credential"
        fi
        
        if op item create \
            --category "$category" \
            --title "$item_title" \
            "${field_name}[${field_type}]"="$field_value" &>/dev/null; then
            print_color $GREEN "✅ Variable creada exitosamente" >&2
        else
            print_color $RED "❌ Error creando variable" >&2
            return 1
        fi
    fi
}

# Función para verificar estado de una variable
check_var_status() {
    local item_title="$1"
    local field_name="$2"
    
    if op item get "$item_title" &>/dev/null; then
        local current_value=$(op item get "$item_title" --field "$field_name" 2>/dev/null || echo "")
        if [ -n "$current_value" ]; then
            echo "✅"
        else
            echo "⚠️"
        fi
    else
        echo "❌"
    fi
}

# Función para mostrar estado general
show_status() {
    print_color $CYAN "Estado actual de las variables:"
    echo ""
    
    print_color $PURPLE "💳 Stripe Webhooks (Específicos por ambiente)"
    print_color $PURPLE "============================================="
    echo "   1. $(check_var_status "NestJS Stripe Webhook DEV" "Webhook Secret") Webhook DEV (Local)"
    echo "   2. $(check_var_status "NestJS Stripe Webhook TEST" "Webhook Secret") Webhook TEST (Fly.io)"
    echo "   3. $(check_var_status "NestJS Stripe Webhook PROD" "Webhook Secret") Webhook PROD (Fly.io)"
    echo ""
    
    print_color $PURPLE "🔑 Stripe API Keys"
    print_color $PURPLE "=================="
    echo "   4. $(check_var_status "NestJS Stripe API TEST" "Secret Key") Secret Key TEST (DEV + TEST)"
    echo "   5. $(check_var_status "NestJS Stripe API PROD" "Secret Key") Secret Key PROD"
    echo ""
    
    print_color $PURPLE "📚 Notion Integration (Compartida)"
    print_color $PURPLE "=================================="
    echo "   6. $(check_var_status "NestJS Notion Integration" "Integration Secret") Integration Secret"
    echo ""
    
    print_color $PURPLE "🗄️ Notion Databases"
    print_color $PURPLE "===================="
    echo "   7. $(check_var_status "NestJS Notion Databases DEV" "Clients Database ID") Clients DB (DEV + TEST)"
    echo "   8. $(check_var_status "NestJS Notion Databases DEV" "Payments Database ID") Payments DB (DEV + TEST)"
    echo "   9. $(check_var_status "NestJS Notion Databases DEV" "Calendar Database ID") Calendar DB (DEV + TEST)"
    echo "   10. $(check_var_status "NestJS Notion Databases PROD" "Clients Database ID") Clients DB (PROD)"
    echo "   11. $(check_var_status "NestJS Notion Databases PROD" "Payments Database ID") Payments DB (PROD)"
    echo "   12. $(check_var_status "NestJS Notion Databases PROD" "Calendar Database ID") Calendar DB (PROD)"
    echo ""
    
    print_color $PURPLE "📱 WhatsApp Configuration (Compartida)"
    print_color $PURPLE "======================================"
    echo "   13. $(check_var_status "NestJS WhatsApp Twilio" "Account SID") Twilio Account SID"
    echo "   14. $(check_var_status "NestJS WhatsApp Twilio" "Auth Token") Twilio Auth Token"
    echo "   15. $(check_var_status "NestJS WhatsApp Twilio" "WhatsApp From") Twilio WhatsApp From"
    echo "   16. $(check_var_status "NestJS WhatsApp Meta" "Use Meta API") Use Meta API (true/false)"
    echo "   17. $(check_var_status "NestJS WhatsApp Meta" "Access Token") Meta Access Token"
    echo "   18. $(check_var_status "NestJS WhatsApp Meta" "Phone Number ID") Meta Phone Number ID"
}

# Función para obtener nombre descriptivo de variable
get_var_name() {
    local var_num=$1
    case $var_num in
        1) echo "Stripe Webhook DEV (Local)" ;;
        2) echo "Stripe Webhook TEST (Fly.io)" ;;
        3) echo "Stripe Webhook PROD (Fly.io)" ;;
        4) echo "Stripe Secret Key TEST (DEV + TEST)" ;;
        5) echo "Stripe Secret Key PROD" ;;
        6) echo "Notion Integration Secret" ;;
        7) echo "Base de Datos de Clientes (DEV + TEST)" ;;
        8) echo "Base de Datos de Pagos (DEV + TEST)" ;;
        9) echo "Base de Datos de Calendario (DEV + TEST)" ;;
        10) echo "Base de Datos de Clientes (PROD)" ;;
        11) echo "Base de Datos de Pagos (PROD)" ;;
        12) echo "Base de Datos de Calendario (PROD)" ;;
        13) echo "Twilio Account SID" ;;
        14) echo "Twilio Auth Token" ;;
        15) echo "Twilio WhatsApp From Number" ;;
        16) echo "Usar Meta WhatsApp API (true/false)" ;;
        17) echo "Meta WhatsApp Access Token" ;;
        18) echo "Meta WhatsApp Phone Number ID" ;;
        *) echo "Variable desconocida" ;;
    esac
}

# Función para gestionar variable específica
manage_variable() {
    local var_num=$1
    local item_title=""
    local field_name=""
    local prefix=""
    local field_type=""
    
    case $var_num in
        1)
            item_title="NestJS Stripe Webhook DEV"
            field_name="Webhook Secret"
            prefix="whsec_"
            field_type="secret"
            ;;
        2)
            item_title="NestJS Stripe Webhook TEST"
            field_name="Webhook Secret"
            prefix="whsec_"
            field_type="secret"
            ;;
        3)
            item_title="NestJS Stripe Webhook PROD"
            field_name="Webhook Secret"
            prefix="whsec_"
            field_type="secret"
            ;;
        4)
            item_title="NestJS Stripe API TEST"
            field_name="Secret Key"
            prefix="sk_test_"
            field_type="secret"
            ;;
        5)
            item_title="NestJS Stripe API PROD"
            field_name="Secret Key"
            prefix="sk_live_"
            field_type="secret"
            ;;
        6)
            item_title="NestJS Notion Integration"
            field_name="Integration Secret"
            prefix="ntn_"
            field_type="secret"
            ;;
        7)
            item_title="NestJS Notion Databases DEV"
            field_name="Clients Database ID"
            prefix=""
            field_type="database_id"
            ;;
        8)
            item_title="NestJS Notion Databases DEV"
            field_name="Payments Database ID"
            prefix=""
            field_type="database_id"
            ;;
        9)
            item_title="NestJS Notion Databases DEV"
            field_name="Calendar Database ID"
            prefix=""
            field_type="database_id"
            ;;
        10)
            item_title="NestJS Notion Databases PROD"
            field_name="Clients Database ID"
            prefix=""
            field_type="database_id"
            ;;
        11)
            item_title="NestJS Notion Databases PROD"
            field_name="Payments Database ID"
            prefix=""
            field_type="database_id"
            ;;
        12)
            item_title="NestJS Notion Databases PROD"
            field_name="Calendar Database ID"
            prefix=""
            field_type="database_id"
            ;;
        13)
            item_title="NestJS WhatsApp Twilio"
            field_name="Account SID"
            prefix="AC"
            field_type="secret"
            ;;
        14)
            item_title="NestJS WhatsApp Twilio"
            field_name="Auth Token"
            prefix=""
            field_type="secret"
            ;;
        15)
            item_title="NestJS WhatsApp Twilio"
            field_name="WhatsApp From"
            prefix="+1415"
            field_type="text"
            ;;
        16)
            item_title="NestJS WhatsApp Meta"
            field_name="Use Meta API"
            prefix=""
            field_type="boolean"
            # Manejo especial para boolean
            echo ""
            print_color $YELLOW "¿Quieres usar Meta WhatsApp Business API en lugar de Twilio?"
            print_color $WHITE "   • true = Usar Meta API (más funcionalidades, más complejo)"
            print_color $WHITE "   • false = Usar Twilio (más fácil, menos funcionalidades)"
            echo -n "Valor (true/false): "
            read bool_value < /dev/tty
            if [[ $bool_value =~ ^(true|false)$ ]]; then
                create_or_update_var "$item_title" "$field_name" "$bool_value" "$field_type"
                echo ""
                print_color $GREEN "Presiona Enter para continuar..."
                read < /dev/tty
            else
                print_color $RED "❌ Valor debe ser 'true' o 'false'"
                print_color $GREEN "Presiona Enter para continuar..."
                read < /dev/tty
            fi
            return
            ;;
        17)
            item_title="NestJS WhatsApp Meta"
            field_name="Access Token"
            prefix=""
            field_type="secret"
            ;;
        18)
            item_title="NestJS WhatsApp Meta"
            field_name="Phone Number ID"
            prefix=""
            field_type="text"
            ;;
        *)
            print_color $RED "❌ Número de variable no válido"
            return 1
            ;;
    esac
    
    local value
    value=$(read_secret "Configurar: $field_name" "$prefix" "$field_type")
    if [ $? -eq 0 ] && [ -n "$value" ]; then
        create_or_update_var "$item_title" "$field_name" "$value" "$field_type"
        echo ""
        print_color $GREEN "Presiona Enter para continuar..."
        read < /dev/tty
    fi
}

# Función para ver valores actuales
show_values() {
    print_color $CYAN "\nValores actuales (enmascarados):"
    echo ""
    
    local vars=(
        "1:NestJS Stripe Webhook DEV:Webhook Secret"
        "2:NestJS Stripe Webhook TEST:Webhook Secret"
        "3:NestJS Stripe Webhook PROD:Webhook Secret"
        "4:NestJS Stripe API TEST:Secret Key"
        "5:NestJS Stripe API PROD:Secret Key"
        "6:NestJS Notion Integration:Integration Secret"
        "7:NestJS Notion Databases DEV:Clients Database ID"
        "8:NestJS Notion Databases DEV:Payments Database ID"
        "9:NestJS Notion Databases DEV:Calendar Database ID"
        "10:NestJS Notion Databases PROD:Clients Database ID"
        "11:NestJS Notion Databases PROD:Payments Database ID"
        "12:NestJS Notion Databases PROD:Calendar Database ID"
        "13:NestJS WhatsApp Twilio:Account SID"
        "14:NestJS WhatsApp Twilio:Auth Token"
        "15:NestJS WhatsApp Twilio:WhatsApp From"
        "16:NestJS WhatsApp Meta:Use Meta API"
        "17:NestJS WhatsApp Meta:Access Token"
        "18:NestJS WhatsApp Meta:Phone Number ID"
    )
    
    for var_info in "${vars[@]}"; do
        IFS=':' read -r num item_title field_name <<< "$var_info"
        
        if op item get "$item_title" &>/dev/null; then
            local value=$(op item get "$item_title" --field "$field_name" --reveal 2>/dev/null || echo "")
            if [ -n "$value" ]; then
                local masked_value
                if [[ $field_name == *"Secret"* ]] || [[ $field_name == *"Key"* ]] || [[ $field_name == *"Token"* ]]; then
                    masked_value="${value:0:10}..."
                elif [[ $field_name == *"Use Meta API"* ]]; then
                    masked_value="$value"
                else
                    masked_value="$value"
                fi
                print_color $GREEN "   $num. $field_name: $masked_value"
            else
                print_color $YELLOW "   $num. $field_name: (sin valor)"
            fi
        else
            print_color $RED "   $num. $field_name: (no existe)"
        fi
    done
    
    echo ""
    print_color $GREEN "Presiona Enter para continuar..."
    read < /dev/tty
}

# Función del menú principal
main_menu() {
    while true; do
        show_header
        show_status
        echo ""
        print_color $CYAN "Opciones:"
        print_color $WHITE "   1-18. Configurar/Modificar variable específica"
        print_color $WHITE "   v. Ver valores actuales"
        print_color $WHITE "   c. Configuración rápida (desarrollo)"
        print_color $WHITE "   p. Configuración rápida (producción)"
        print_color $WHITE "   w. Configuración rápida (WhatsApp)"
        print_color $WHITE "   q. Salir"
        echo ""
        echo -n "Selecciona una opción: "
        read choice < /dev/tty
        
        case $choice in
            1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18)
                manage_variable "$choice"
                ;;
            "v"|"V")
                show_values
                ;;
            "c"|"C")
                print_color $YELLOW "🚀 Configuración rápida para desarrollo..."
                
                for var_num in 1 4 6 7 8; do
                    local var_name=$(get_var_name "$var_num")
                    print_color $BLUE "\n📝 Configurando: $var_name"
                    manage_variable "$var_num"
                done
                ;;
            "p"|"P")
                print_color $YELLOW "🚀 Configuración rápida para producción..."
                print_color $RED "⚠️  ATENCIÓN: Vas a configurar variables de PRODUCCIÓN"
                echo -n "¿Continuar? (yes/no): "
                read confirm < /dev/tty
                if [[ $confirm == "yes" ]]; then
                    for var_num in 5 10 11; do
                        local var_name=$(get_var_name "$var_num")
                        print_color $BLUE "\n📝 Configurando: $var_name"
                        manage_variable "$var_num"
                    done
                fi
                ;;
            "w"|"W")
                print_color $YELLOW "📱 Configuración rápida para WhatsApp..."
                print_color $BLUE "\nElige tu proveedor de WhatsApp:"
                print_color $WHITE "   1. Twilio (recomendado para empezar)"
                print_color $WHITE "   2. Meta WhatsApp Business API (más funcionalidades)"
                print_color $WHITE "   3. Configurar ambos"
                echo -n "Opción (1/2/3): "
                read whatsapp_choice < /dev/tty
                
                case $whatsapp_choice in
                    1)
                        print_color $BLUE "\n🔧 Configurando Twilio..."
                        for var_num in 13 14; do
                            local var_name=$(get_var_name "$var_num")
                            print_color $BLUE "\n📝 Configurando: $var_name"
                            manage_variable "$var_num"
                        done
                        # Configurar Meta API como false
                        create_or_update_var "NestJS WhatsApp Meta" "Use Meta API" "false" "boolean"
                        ;;
                    2)
                        print_color $BLUE "\n🔧 Configurando Meta WhatsApp Business API..."
                        for var_num in 16 17; do
                            local var_name=$(get_var_name "$var_num")
                            print_color $BLUE "\n📝 Configurando: $var_name"
                            manage_variable "$var_num"
                        done
                        ;;
                    3)
                        print_color $BLUE "\n🔧 Configurando ambos proveedores..."
                        for var_num in 13 14 16 17; do
                            local var_name=$(get_var_name "$var_num")
                            print_color $BLUE "\n📝 Configurando: $var_name"
                            manage_variable "$var_num"
                        done
                        ;;
                    *)
                        print_color $RED "❌ Opción no válida"
                        ;;
                esac
                ;;
            "q"|"Q")
                print_color $GREEN "👋 ¡Hasta luego!"
                exit 0
                ;;
            *)
                print_color $RED "❌ Opción no válida"
                sleep 1
                ;;
        esac
    done
}

# Función principal
main() {
    check_1password
    main_menu
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 