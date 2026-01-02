# =============================================================================
# Kyx MCP Server - Multi-stage Dockerfile
# =============================================================================
# Stage 1: Build - Uses Rust nightly (for edition2024 support)
# Stage 2: Runtime - Debian slim with required libraries
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder (Rust nightly)
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    pkg-config \
    libssl-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust nightly via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Copy dependency files first for better caching
COPY Cargo.toml Cargo.lock ./

# Create dummy main.rs for dependency caching
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies (this layer will be cached)
RUN cargo build --release && rm -rf src target/release/kyx-governance*

# Copy actual source code
COPY src ./src
COPY migrations ./migrations

# Build the actual application
RUN cargo build --release --bin kyx-governance



# -----------------------------------------------------------------------------
# Stage 2: Runtime (Debian slim with OpenSSL)
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/*

# Labels
LABEL org.opencontainers.image.title="Kyx MCP Server"
LABEL org.opencontainers.image.description="Kyx Governance Hub - MCP Server"
LABEL org.opencontainers.image.version="0.1.0"
LABEL org.opencontainers.image.vendor="Kyx Tech"

# Create non-root user
RUN groupadd -r kyx && useradd -r -g kyx kyx

# Copy the compiled binary from builder
COPY --from=builder /app/target/release/kyx-mcp /usr/local/bin/kyx-mcp

# Copy migrations for auto-seeding
COPY --from=builder /app/migrations /migrations

# Set ownership
RUN chown -R kyx:kyx /migrations

# Expose HTTP port
EXPOSE 3001

# Run as non-root user
USER kyx

# Set default environment variables
ENV MCP_TRANSPORT=http
ENV PORT=3001
ENV RUST_LOG=info

# Run the binary
ENTRYPOINT ["/usr/local/bin/kyx-mcp"]
