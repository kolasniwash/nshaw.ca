FROM ghcr.io/getzola/zola:v0.18.0 AS builder

WORKDIR /app
COPY /content /app/content
COPY /templates /app/templates
COPY /config.toml /app/config.toml
COPY /static /app/static
COPY /themes /app/themes
COPY fly.toml /app/fly.toml
RUN ["zola", "build"]

FROM joseluisq/static-web-server:2
COPY --from=builder /app/public /public
ENV SERVER_PORT 8080