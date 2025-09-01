# ---------- BUILD ----------
  FROM erlang:28-alpine AS build
  WORKDIR /app
  RUN apk add --no-cache build-base git

  COPY _build .
  COPY _build/rebar.config rebar.config
  COPY config config
  RUN rebar3 as prod release

# ---------- RUNTIME ----------
  FROM alpine:3.20 AS runtime
  WORKDIR /app
  # libs mínimas para o ERTS/OTP no Alpine
  RUN apk add --no-cache \
      libstdc++ \
      libgcc \
      ncurses-libs \
      openssl \
      zlib \
      bash
  COPY --from=build /app/_build/prod/rel/banking_core ./
  COPY distributed/entrypoint.sh /app/entrypoint.sh
  COPY config/vm.args /app/releases/0.1.0/vm.args
  RUN chmod +x /app/entrypoint.sh
  ENTRYPOINT ["/app/entrypoint.sh"]
  # ENTRYPOINT ["bin/banking_core", "foreground"]