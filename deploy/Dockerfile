# ---------- BUILD STAGE ----------
FROM elixir:1.18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

COPY . .
RUN rm -rf _build deps

# Install dependencies
RUN mix deps.get --only prod

# Compile and build release with ERTS included
RUN MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release bank --overwrite

# ---------- RUNTIME STAGE ----------
FROM alpine:3.22.1 AS runtime

# Install only runtime dependencies (no Elixir/Erlang)
RUN apk add --no-cache \
    libstdc++ \
    libgcc \
    openssl \
    zlib \
    ncurses-libs \
    ncurses-terminfo-base \
    bash ca-certificates

# Create app user
RUN adduser -D -s /bin/sh app

# Set working directory
WORKDIR /app

# Copy the entire release from builder stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/bank ./

USER app
# Start the application
CMD ["./bin/bank", "start"]
