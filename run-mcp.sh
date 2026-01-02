#!/bin/bash
cd /Users/beykyu/Developer/kyx-tech/kyx-mcp
export $(grep -v '^#' .env | xargs)

# Debug: log all stdin/stdout to files
# exec ./target/debug/kyx-mcp 2>>/tmp/mcp-stderr.log | tee -a /tmp/mcp-stdout.log

# Run via Docker (stdio mode)
# -i: Keep stdin open
# --rm: Remove container after exit
# --network: Connect to the same network as database
# -e MCP_TRANSPORT=stdio: Force stdio mode
# -e SURREAL_URL=ws://surrealdb:8000: Connect to DB service name
docker run -i --rm \
  --network kyx-mcp_kyx-network \
  -e MCP_TRANSPORT=stdio \
  -e SURREAL_URL=ws://surrealdb:8000 \
  -e SURREAL_NAMESPACE=kyx \
  -e SURREAL_DATABASE=governance \
  -e SURREAL_USER=root \
  -e SURREAL_PASS=devpassword123 \
  -e RUST_LOG=info \
  kyx-mcp-kyx-mcp
