FROM node:18 AS base

FROM base as wasp-builder
ADD . .
RUN curl -sSL https://get.wasp-lang.dev/installer.sh | sh \
    && /root/.local/bin/wasp build

FROM base AS server-builder
WORKDIR /server
COPY --from=wasp-builder ./.wasp/build/server ./
RUN npm install \
    && npm run build

FROM base AS web-app-builder
WORKDIR /web-app
COPY --from=wasp-builder ./.wasp/build/web-app ./
RUN npm install \
    && npm run build


FROM base AS server-production
WORKDIR /app/server
ENV NODE_ENV production
COPY --from=wasp-builder ./.wasp/build/server/node_modules ./node_modules
COPY --from=wasp-builder ./.wasp/build/server/package*.json ./
COPY --from=wasp-builder ./.wasp/build/server/scripts ./scripts
COPY --from=server-builder /server/dist ./dist
COPY --from=wasp-builder ./.wasp/build/db ../db
EXPOSE ${PORT}
ENTRYPOINT ["npm", "run", "start-production"]


FROM joseluisq/static-web-server AS web-app-production
COPY --from=web-app-builder /web-app/build /public

