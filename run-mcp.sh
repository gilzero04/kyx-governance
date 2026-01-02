#!/bin/bash
cd /Users/beykyu/Developer/kyx-tech/kyx-governance
export $(grep -v '^#' .env | xargs)

# Debug: log all stdin/stdout to files
# exec ./target/debug/kyx-governance 2>>/tmp/mcp-stderr.log | tee -a /tmp/mcp-stdout.log

# Run via Docker (stdio mode)
# -i: Keep stdin open
# --rm: Remove container after exit
# --network: Connect to the same network as database
# -e MCP_TRANSPORT=stdio: Force stdio mode
# -e SURREAL_URL=ws://kyx-governance-surrealdb:8000: Connect to DB service name
# Log everything for debugging
# Log everything to absolute path for debugging
exec 5> >(tee -a /tmp/mcp_agent_debug.log >&2)
exec 6> >(tee -a /tmp/mcp_agent_debug.log)

# Check if container is running
if [ "$(docker ps -q -f name=kyx-governance)" ]; then
    # Container is running, execution via exec
    exec docker exec -i \
        -e MCP_TRANSPORT=stdio \
        -e RUST_LOG=info \
        kyx-governance \
        /usr/local/bin/kyx-governance 2>&5 >&6
else
    # Fallback to run (slow)
    docker run \
        --rm -i \
        --network kyx-governance_kyx-network \
        -e SURREAL_URL="ws://kyx-governance-surrealdb:8000/rpc" \
        -e SURREAL_USER="root" \
        -e SURREAL_PASS="${SURREAL_PASS}" \
        -e SURREAL_NAMESPACE="kyx" \
        -e SURREAL_DATABASE="governance" \
        -e MCP_TRANSPORT="stdio" \
        -e RUST_LOG="info" \
        kyx-governance \
        /usr/local/bin/kyx-governance 2>&5 >&6
fi
