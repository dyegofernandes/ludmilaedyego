# syntax=docker/dockerfile:1
# Build context: raiz do repositório (docker-compose.yml)

FROM node:22-alpine AS deps
WORKDIR /app
COPY apps/api/package*.json ./
COPY apps/api/prisma ./prisma/
RUN npm ci

FROM node:22-alpine AS build
WORKDIR /app
RUN apk add --no-cache openssl libc6-compat
COPY --from=deps /app/node_modules ./node_modules
COPY apps/api/ ./
RUN npx prisma generate && npm run build && npm prune --omit=dev

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache openssl libc6-compat
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/package*.json ./
COPY apps/api/scripts/docker-bootstrap.js ./scripts/docker-bootstrap.js
COPY apps/api/scripts/docker-seed.js ./scripts/docker-seed.js
COPY apps/api/docker-entrypoint.sh ./docker-entrypoint.sh
RUN sed -i 's/\r$//' ./docker-entrypoint.sh \
  && chmod +x ./docker-entrypoint.sh \
  && mkdir -p uploads
EXPOSE 3000
ENTRYPOINT ["./docker-entrypoint.sh"]
