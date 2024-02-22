FROM ghcr.io/getzola/zola:v0.18.0 AS zola

WORKDIR /app
COPY . .
RUN ["zola", "build"]

FROM ghcr.io/static-web-server/static-web-server:2
COPY --from=zola /app/public /public
