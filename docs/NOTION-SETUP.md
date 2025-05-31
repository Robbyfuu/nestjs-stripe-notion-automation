# 📚 Configuración de Notion

Guía detallada para configurar las bases de datos de Notion requeridas por la aplicación.

## 🌍 Estrategia de Ambientes

Esta aplicación usa **2 ambientes separados**:
- 🧪 **Development/Staging**: Para pruebas y desarrollo
- 🏭 **Production**: Para datos reales de clientes

**Necesitarás crear 4 bases de datos en total**: 2 para cada ambiente.

## 🔗 Crear Integración

1. Ve a [Notion Integrations](https://www.notion.so/my-integrations)
2. Crea una nueva integración con nombre: "NestJS Stripe Automation"
3. Obtén el **Internal Integration Token** (empieza con `secret_`)
4. Guárdalo en 1Password ejecutando: `pnpm run setup:notion`

## 🗂️ Bases de Datos Requeridas

### 📋 Base de Datos "Clientes DEV" (Development)

```
Propiedades requeridas:
├── Nombre (Title) - Nombre completo del cliente
├── Email (Email) - Correo electrónico único
├── Teléfono (Phone) - Número de contacto
├── Total Pagado (Number) - Suma de todos los pagos
├── Fecha Último Pago (Date) - Última transacción
└── Categoría (Select) - Nuevo | Recurrente | VIP
```

### 💰 Base de Datos "Pagos de Stripe DEV" (Development)

```
Propiedades requeridas:
├── Nombre del Pago (Title) - Descripción del producto/servicio
├── Monto (Number) - Cantidad en centavos (ej: 2500 = $25.00)
├── Moneda (Select) - USD | EUR | MXN | etc.
├── Fecha de Pago (Date) - Timestamp del pago
├── Correo electrónico (Email) - Email del cliente
├── Cliente (Relation) - Relación a base de datos "Clientes DEV"
├── Estado (Select) - Completado | Pendiente | Fallido
├── ID de Transacción (Text) - Payment Intent ID de Stripe
└── Método de Pago (Select) - card | bank_transfer | apple_pay | etc.
```

### 📋 Base de Datos "Clientes PROD" (Production)

```
Propiedades requeridas:
├── Nombre (Title) - Nombre completo del cliente
├── Email (Email) - Correo electrónico único
├── Teléfono (Phone) - Número de contacto
├── Total Pagado (Number) - Suma de todos los pagos
├── Fecha Último Pago (Date) - Última transacción
└── Categoría (Select) - Nuevo | Recurrente | VIP
```

### 💰 Base de Datos "Pagos de Stripe PROD" (Production)

```
Propiedades requeridas:
├── Nombre del Pago (Title) - Descripción del producto/servicio
├── Monto (Number) - Cantidad en centavos (ej: 2500 = $25.00)
├── Moneda (Select) - USD | EUR | MXN | etc.
├── Fecha de Pago (Date) - Timestamp del pago
├── Correo electrónico (Email) - Email del cliente
├── Cliente (Relation) - Relación a base de datos "Clientes PROD"
├── Estado (Select) - Completado | Pendiente | Fallido
├── ID de Transacción (Text) - Payment Intent ID de Stripe
└── Método de Pago (Select) - card | bank_transfer | apple_pay | etc.
```

**Configuración:**
- Crear 4 páginas nuevas en Notion
- Agregar base de datos con los nombres correspondientes
- Configurar todas las propiedades según las tablas anteriores
- En "Cliente" → Relation → Seleccionar la base de datos de clientes correspondiente
- Compartir TODAS las bases de datos con tu integración (botón "..." → Add connections)

## 🔑 Obtener Database IDs

1. **Abre cada base de datos** en Notion
2. **Copia la URL** del navegador
3. **Extrae el ID** de la URL:

```
URL: https://notion.so/workspace/DATABASE_ID?v=...
                              ^^^^^^^^^^^^
                              Este es el ID (32 caracteres)
```

**Ejemplo:**
```
URL: https://notion.so/workspace/1ff5936934af804ebffbfbbab7375e27?v=abc123
ID:  1ff5936934af804ebffbfbbab7375e27
```

4. **Guarda en 1Password** usando los scripts:
   ```bash
   # Para bases de datos de DESARROLLO
   pnpm run setup:dev
   
   # Para bases de datos de PRODUCCIÓN
   pnpm run setup:prod
   ```

## 📊 Resumen de Configuración

| Ambiente | Base de Datos | 1Password Entry | Campo |
|----------|---------------|-----------------|-------|
| **DEV** | Clientes DEV | `NestJS Notion Databases` | `Clients Database ID` |
| **DEV** | Pagos DEV | `NestJS Notion Databases` | `Payments Database ID` |
| **PROD** | Clientes PROD | `NestJS Notion Databases PROD` | `Clients Database ID` |
| **PROD** | Pagos PROD | `NestJS Notion Databases PROD` | `Payments Database ID` |

## ✅ Verificación

Para verificar que todo está configurado correctamente:

1. **Tu integración tiene acceso** a las 4 bases de datos
2. **Los IDs están guardados** en 1Password correctamente  
3. **Las propiedades coinciden** exactamente con los nombres especificados
4. **Las relaciones** entre Clientes y Pagos están configuradas en cada ambiente
5. **Los ambientes están separados** (DEV no debe apuntar a PROD)

## 🔍 Troubleshooting Notion

### Error: "database_not_found"
- ✅ Verifica que la integración tenga acceso a la base de datos
- ✅ Confirma que el Database ID sea correcto (32 caracteres)
- ✅ Asegúrate de estar usando el ID del ambiente correcto

### Error: "property not found"
- ✅ Revisa que los nombres de las propiedades coincidan exactamente
- ✅ Verifica que el tipo de propiedad sea correcto (Email, Date, etc.)

### Error: "unauthorized"
- ✅ Confirma que el Integration Token sea válido
- ✅ Verifica que la integración esté conectada a las bases de datos

### La relación no funciona
- ✅ Asegúrate de que ambas bases de datos estén en el mismo workspace
- ✅ Verifica que la propiedad "Cliente" apunte a la base de datos correcta del mismo ambiente
- ✅ Confirma que DEV apunte a DEV y PROD apunte a PROD

### Datos en ambiente incorrecto
- ✅ Verifica que estés usando las credenciales correctas en cada ambiente
- ✅ Confirma que los Database IDs estén en las entradas correctas de 1Password
- ✅ Revisa los logs para confirmar qué base de datos se está usando 