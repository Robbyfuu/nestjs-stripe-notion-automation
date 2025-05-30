# Configuración de Biome

Este proyecto usa [Biome](https://biomejs.dev/) como herramienta de linting y formateo, reemplazando ESLint y Prettier.

## ¿Qué es Biome?

Biome es una herramienta moderna que combina:
- **Linter**: Análisis estático de código (como ESLint)
- **Formatter**: Formateo automático de código (como Prettier)
- **Import sorting**: Organización automática de imports
- **Rendimiento**: Hasta 10x más rápido que ESLint

## Scripts disponibles

### Verificación completa
```bash
pnpm run check          # Verifica formato, imports y linting
pnpm run check:fix      # Aplica correcciones automáticas seguras
```

### Solo formateo
```bash
pnpm run format         # Formatea todo el código
pnpm run format:check   # Solo verifica el formato sin cambiar archivos
```

### Solo linting
```bash
pnpm run lint           # Ejecuta el linter
pnpm run lint:fix       # Ejecuta el linter y aplica correcciones
```

### Scripts legacy (ESLint/Prettier)
```bash
pnpm run format:legacy  # Prettier (mantener por compatibilidad)
pnpm run lint:legacy    # ESLint (mantener por compatibilidad)
```

## Configuración

La configuración está en `biome.json` y está optimizada para NestJS:

- **Indentación**: 2 espacios
- **Comillas**: Simples (`'`)
- **Punto y coma**: Siempre
- **Comas finales**: Siempre
- **Ancho de línea**: 100 caracteres
- **Decoradores de parámetros**: Habilitados (para NestJS)

## Integración con el editor

### VS Code
Instala la extensión oficial de Biome:
```bash
ext install biomejs.biome
```

### Configuración recomendada para VS Code
Agrega en tu `settings.json`:
```json
{
  "[javascript]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[typescript]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[json]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "editor.codeActionsOnSave": {
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  }
}
```

## Migración desde ESLint/Prettier

Si quieres migrar completamente:

1. **Desinstalar herramientas anteriores** (opcional):
```bash
pnpm remove eslint prettier @eslint/eslintrc @eslint/js eslint-config-prettier eslint-plugin-prettier typescript-eslint
```

2. **Eliminar archivos de configuración** (opcional):
```bash
rm eslint.config.mjs .prettierrc
```

3. **Actualizar scripts en package.json** (ya hecho):
- Cambiar `format` y `lint` para usar Biome
- Mantener scripts legacy como respaldo

## Comandos útiles

```bash
# Verificar un archivo específico
pnpx biome check src/app.module.ts

# Formatear un archivo específico
pnpx biome format --write src/app.module.ts

# Verificar solo archivos TypeScript
pnpx biome check "src/**/*.ts"

# Ver estadísticas de rendimiento
pnpx biome check --verbose .
```

## Reglas personalizadas

Las reglas están configuradas para ser amigables con NestJS:

- ✅ Decoradores de parámetros habilitados
- ⚠️ `any` permitido con warning (útil para tipos de Stripe)
- ❌ Variables no utilizadas marcadas como error
- ✅ Import types forzados para mejor tree-shaking

## Problemas comunes

### Decoradores de parámetros
Si ves errores sobre decoradores en parámetros de controladores NestJS, asegúrate de que `unsafeParameterDecoratorsEnabled: true` esté en la configuración.

### Tipos `any`
El proyecto permite `any` con warning. Para tipado estricto, cambiar en `biome.json`:
```json
"suspicious": {
  "noExplicitAny": "error"
}
```

### Performance
Biome es significativamente más rápido que ESLint. En un proyecto típico:
- ESLint: ~3-5 segundos
- Biome: ~300-500ms 