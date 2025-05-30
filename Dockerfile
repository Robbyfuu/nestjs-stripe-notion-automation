# Multi-stage build para optimizar el tamaño de la imagen final
FROM node:20-alpine3.21 AS base

# Actualizar paquetes del sistema para resolver vulnerabilidades
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Instalar pnpm globalmente
RUN npm install -g pnpm

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración de dependencias
COPY package.json pnpm-lock.yaml ./

# Stage para instalar dependencias
FROM base AS deps
RUN pnpm install --frozen-lockfile

# Stage para build
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build de la aplicación
RUN pnpm run build

# Stage para producción
FROM node:20-alpine3.21 AS production

# Actualizar paquetes del sistema para resolver vulnerabilidades
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Instalar pnpm
RUN npm install -g pnpm

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

WORKDIR /app

# Copiar archivos de configuración
COPY package.json pnpm-lock.yaml ./

# Instalar solo dependencias de producción
RUN pnpm install --prod --frozen-lockfile && pnpm store prune

# Copiar el build desde el stage anterior
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist
COPY --from=build --chown=nestjs:nodejs /app/scripts ./scripts

# Cambiar al usuario no-root
USER nestjs

# Exponer puerto
EXPOSE 3000

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node scripts/health-check.js || exit 1

# Usar dumb-init para manejo correcto de señales
ENTRYPOINT ["dumb-init", "--"]

# Comando para ejecutar la aplicación
CMD ["node", "dist/main"] 