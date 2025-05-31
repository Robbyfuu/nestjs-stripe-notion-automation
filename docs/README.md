# 📚 Documentación Técnica

Documentación completa del sistema NestJS Stripe Notion Automation.

## 📋 Documentación Disponible

| Documento | Descripción | Audiencia |
|-----------|-------------|-----------|
| **[README Principal](../README.md)** | Guía de inicio rápido y comandos | Todos |
| **[Workflow de Desarrollo](../DEVELOPMENT.md)** | Branches, commits y deployment | Desarrolladores |
| **[Arquitectura del Sistema](ARCHITECTURE.md)** | Diagramas técnicos completos | Desarrolladores/DevOps |
| **[Configuración de Notion](NOTION-SETUP.md)** | Setup detallado de bases de datos | Desarrolladores |
| **[GitHub Actions Setup](GITHUB-ACTIONS-SETUP.md)** | Configuración de CI/CD automático | DevOps |

## 🎯 Por dónde empezar

### 🚀 Setup inicial
1. Lee **[README Principal](../README.md)** para configurar el proyecto
2. Configura integración con `pnpm run setup:notion`
3. Configura credenciales con `pnpm run setup:dev` y `pnpm run setup:prod`
4. Configura bases de datos siguiendo **[Configuración de Notion](NOTION-SETUP.md)**
5. Ejecuta `pnpm run dev` para desarrollo

### 👨‍💻 Para desarrolladores
1. Lee **[Workflow de Desarrollo](../DEVELOPMENT.md)** para el flujo de trabajo
2. Revisa **[Arquitectura](ARCHITECTURE.md)** para entender el sistema
3. Crea tu feature branch desde `develop`

### 🚀 Para configurar CI/CD
1. **[GitHub Actions Setup](GITHUB-ACTIONS-SETUP.md)** tiene la guía completa:
   - Crear apps en Fly.io
   - Configurar tokens en GitHub
   - Flujo de deployment automático
   - Troubleshooting común

### 🏗️ Para entender la arquitectura
1. **[Arquitectura del Sistema](ARCHITECTURE.md)** tiene todos los diagramas:
   - Flujo completo de pagos
   - Módulos de NestJS  
   - Estructura de datos
   - Infraestructura y deployment
   - Seguridad y escalabilidad

---

*💡 La documentación está organizada para diferentes niveles: desde setup inicial hasta arquitectura técnica detallada y configuración de CI/CD.* 