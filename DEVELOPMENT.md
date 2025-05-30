# 🌿 Workflow de Desarrollo

Guía para mantener `main` limpio y trabajar de forma organizada.

## 📋 Estructura de Branches

```
main        ← Código estable y production-ready
├── develop ← Branch principal de desarrollo
├── feature/nueva-funcionalidad
├── fix/corrección-bug
└── hotfix/emergencia-producción
```

## 🔄 Workflow Recomendado

### Para nuevas funcionalidades:
```bash
# 1. Crear branch desde develop
git checkout develop
git pull origin develop
git checkout -b feature/nombre-funcionalidad

# 2. Desarrollar y commits
git add .
git commit -m "feat: descripción de la funcionalidad"

# 3. Push y Pull Request
git push origin feature/nombre-funcionalidad
# Crear PR hacia develop en GitHub
```

### Para fixes:
```bash
# 1. Crear branch desde develop
git checkout develop
git checkout -b fix/descripción-del-bug

# 2. Corregir y commit
git commit -m "fix: descripción del fix"

# 3. Push y merge
git push origin fix/descripción-del-bug
```

### Para hotfixes (emergencias en producción):
```bash
# 1. Crear desde main
git checkout main
git checkout -b hotfix/emergencia

# 2. Fix rápido
git commit -m "hotfix: descripción urgente"

# 3. Merge a main Y develop
git checkout main
git merge hotfix/emergencia
git push origin main

git checkout develop
git merge hotfix/emergencia
git push origin develop
```

## 🚀 Despliegue a Producción

### Desde develop a main:
```bash
# 1. Actualizar develop
git checkout develop
git pull origin develop

# 2. Merge a main
git checkout main
git pull origin main
git merge develop

# 3. Deploy automático
git push origin main
# Esto triggerea deployment en Fly.io
```

## 📝 Convenciones de Commits

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| `feat` | Nueva funcionalidad | `feat: add payment notifications` |
| `fix` | Corrección de bug | `fix: webhook signature validation` |
| `docs` | Documentación | `docs: update deployment guide` |
| `refactor` | Refactoring | `refactor: improve error handling` |
| `test` | Tests | `test: add webhook validation tests` |
| `chore` | Mantenimiento | `chore: update dependencies` |

## 🔧 Comandos Útiles

```bash
# Ver todas las branches
git branch -a

# Cambiar a develop
git checkout develop

# Actualizar branch actual
git pull origin $(git branch --show-current)

# Limpiar branches locales ya mergeadas
git branch --merged | grep -v "main\|develop" | xargs -n 1 git branch -d

# Ver diferencias entre branches
git diff main..develop
```

## 🎯 Estado Actual

- ✅ **main**: Estable, desplegado en producción
- 🚧 **develop**: Branch activo para desarrollo
- 📦 **Producción**: https://nestjs-stripe-notion.fly.dev

## 🔗 Próximos pasos

1. Siempre trabajar desde `develop`
2. Crear feature branches para nuevas funcionalidades
3. PRs hacia `develop` para review
4. Merge a `main` solo cuando esté testeado
5. Deploy automático desde `main` 