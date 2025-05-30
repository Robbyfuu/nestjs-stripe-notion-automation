# 📚 Configuración de Notion

Guía detallada para configurar las bases de datos de Notion requeridas por la aplicación.

## 🔗 Crear Integración

1. Ve a [Notion Integrations](https://www.notion.so/my-integrations)
2. Crea una nueva integración con nombre: "NestJS Stripe Automation"
3. Obtén el **Internal Integration Token** (empieza con `secret_`)
4. Guárdalo en 1Password como se indica en el README principal

## 🗂️ Bases de Datos Requeridas

### 📋 Base de Datos "Clientes"

```
Propiedades requeridas:
├── Nombre (Title) - Nombre completo del cliente
├── Email (Email) - Correo electrónico único
├── Teléfono (Phone) - Número de contacto
├── Total Pagado (Number) - Suma de todos los pagos
├── Fecha Último Pago (Date) - Última transacción
└── Categoría (Select) - Nuevo | Recurrente | VIP
```

**Configuración:**
- Crear página nueva en Notion
- Agregar base de datos con el nombre "Clientes"
- Configurar todas las propiedades según la tabla anterior
- Compartir con tu integración (botón "..." → Add connections)

### 💰 Base de Datos "Pagos de Stripe"

```
Propiedades requeridas:
├── Nombre del Pago (Title) - Descripción del producto/servicio
├── Monto (Number) - Cantidad en centavos (ej: 2500 = $25.00)
├── Moneda (Select) - USD | EUR | MXN | etc.
├── Fecha de Pago (Date) - Timestamp del pago
├── Correo electrónico (Email) - Email del cliente
├── Cliente (Relation) - Relación a base de datos "Clientes"
├── Estado (Select) - Completado | Pendiente | Fallido
├── ID de Transacción (Text) - Payment Intent ID de Stripe
└── Método de Pago (Select) - card | bank_transfer | apple_pay | etc.
```

**Configuración:**
- Crear página nueva en Notion
- Agregar base de datos con el nombre "Pagos de Stripe"
- Configurar todas las propiedades según la tabla anterior
- En "Cliente" → Relation → Seleccionar base de datos "Clientes"
- Compartir con tu integración

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

4. **Guarda en 1Password** usando:
   ```bash
   # Para base de datos de Clientes
   op item edit "NestJS Notion Databases" "Clients Database ID[text]"="TU_ID_DE_CLIENTES"
   
   # Para base de datos de Pagos
   op item edit "NestJS Notion Databases" "Payments Database ID[text]"="TU_ID_DE_PAGOS"
   ```

## ✅ Verificación

Para verificar que todo está configurado correctamente:

1. **Tus integraciones tienen acceso** a ambas bases de datos
2. **Los IDs están guardados** en 1Password correctamente  
3. **Las propiedades coinciden** exactamente con los nombres especificados
4. **La relación** entre Clientes y Pagos está configurada

## 🔍 Troubleshooting Notion

### Error: "database_not_found"
- ✅ Verifica que la integración tenga acceso a la base de datos
- ✅ Confirma que el Database ID sea correcto (32 caracteres)

### Error: "property not found"
- ✅ Revisa que los nombres de las propiedades coincidan exactamente
- ✅ Verifica que el tipo de propiedad sea correcto (Email, Date, etc.)

### Error: "unauthorized"
- ✅ Confirma que el Integration Token sea válido
- ✅ Verifica que la integración esté conectada a las bases de datos

### La relación no funciona
- ✅ Asegúrate de que ambas bases de datos estén en el mismo workspace
- ✅ Verifica que la propiedad "Cliente" apunte a la base de datos correcta 