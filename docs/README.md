# 📚 Documentación Técnica

Documentación completa del sistema NestJS Stripe Notion Automation.

## 📋 Índice de Documentación

### 🏗️ Arquitectura y Diseño
- **[Arquitectura del Sistema](ARCHITECTURE.md)** - Diagramas completos del sistema
  - Diagrama de arquitectura general
  - Flujo de datos detallado
  - Arquitectura de módulos NestJS
  - Estructura de bases de datos
  - Gestión de credenciales
  - Infraestructura de deployment

### 🔧 Desarrollo
- **[Workflow de Desarrollo](../DEVELOPMENT.md)** - Guía de branches y convenciones
- **[README Principal](../README.md)** - Guía de inicio rápido

## 🎯 Audiencia

### Para Desarrolladores
- Entiende la arquitectura modular
- Flujos de datos entre servicios
- Patrones de diseño implementados
- Configuración de credenciales

### Para DevOps/Infraestructura  
- Deployment en Fly.io
- Configuración de Docker
- Gestión de secretos con 1Password
- Monitoreo y métricas

### Para Product/Business
- Flujo completo de pagos
- Integración Stripe ↔ Notion
- Consideraciones de escalabilidad
- Métricas de negocio disponibles

## 🔍 Vistas de Arquitectura

| Vista | Propósito | Audiencia |
|-------|-----------|-----------|
| **General** | Overview del sistema completo | Todos |
| **Flujo de Datos** | Secuencia de operaciones | Desarrolladores |
| **Módulos NestJS** | Estructura interna | Desarrolladores |
| **Base de Datos** | Modelo de datos | Desarrolladores/BA |
| **Credenciales** | Gestión de secretos | DevOps |
| **Infraestructura** | Deployment y hosting | DevOps |
| **Monitoreo** | Métricas y observabilidad | DevOps/Product |

## 🚀 Próximos Pasos

1. **Leer [Arquitectura](ARCHITECTURE.md)** para entender el sistema
2. **Revisar [Desarrollo](../DEVELOPMENT.md)** para workflow
3. **Seguir [README](../README.md)** para setup inicial 