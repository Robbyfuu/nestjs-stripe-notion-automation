# 🐳 Dockerfile para NestJS + Stripe + Notion + WhatsApp
FROM node:20-alpine AS base

# Instalar 1Password CLI y herramientas necesarias
RUN apk add --no-cache \
    curl \
    bash \
    && curl -sSfO https://cache.agilebits.com/dist/1P/op2/pkg/v2.26.0/op_linux_amd64_v2.26.0.zip \
    && unzip op_linux_amd64_v2.26.0.zip \
    && mv op /usr/local/bin/ \
    && rm op_linux_amd64_v2.26.0.zip

# Instalar pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copiar archivos de dependencias
COPY package.json pnpm-lock.yaml ./

# ================================
# Desarrollo
# ================================
FROM base AS development

# Instalar todas las dependencias (incluyendo devDependencies)
RUN pnpm install --frozen-lockfile

# Copiar código fuente
COPY . .

# Copiar archivos de configuración de 1Password
COPY 1password-*.env ./

# Copiar script de entrypoint
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Exponer puerto
EXPOSE 3000

# Usar entrypoint personalizado
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Comando por defecto para desarrollo
CMD ["pnpm", "run", "start:dev"]

# ================================
# Build
# ================================
FROM base AS build

# Instalar dependencias
RUN pnpm install --frozen-lockfile

# Copiar código fuente
COPY . .

# Build de la aplicación
RUN pnpm run build

# ================================
# Producción
# ================================
FROM base AS production

# Instalar solo dependencias de producción
RUN pnpm install --frozen-lockfile --prod

# Copiar build desde la etapa build
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./

# Copiar archivos de configuración de 1Password
COPY 1password-*.env ./

# Copiar script de entrypoint
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001
USER nestjs

# Exponer puerto
EXPOSE 3000

# Usar entrypoint personalizado
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Comando para producción
CMD ["node", "dist/main"] 