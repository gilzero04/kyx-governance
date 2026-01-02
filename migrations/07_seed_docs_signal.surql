USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- PRD
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:signal,
    sdlc_phase: "planning",
    name: "prd",
    title: "Signal PRD",
    content: "# Kyx Signal PRD\n\n## Objective\nTo provide a high-frequency event hub and real-time communication layer using WebSockets and Redis.\n\n## Core Features\n1. **Pub/Sub Engine**: Low-latency event broadcasting.\n2. **State Sync**: Real-time synchronization of state across clients.\n3. **Scalability**: Horizontal scaling with Redis clusters.",
    mimeType: "text/markdown"
};

-- Architecture (Signal)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:signal,
    sdlc_phase: "design",
    name: "architecture",
    title: "Signal Hub Architecture",
    content: "# Kyx Signal Architecture\n\n## Tech Stack\n- **Engine**: Go or Rust (High concurrency)\n- **State Store**: Redis (Pub/Sub + Streams)\n- **Protocol**: WebSockets (Secure)\n\n## Components\n1. **Event Bus**: Captures and routes system-wide events.\n2. **Socket Gateway**: Manages persistent client connections.\n3. **Presence Engine**: Tracks active users and service health.",
    mimeType: "text/markdown"
};

-- Test Plan (Signal)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:signal,
    sdlc_phase: "verification",
    name: "test-plan",
    title: "Signal Hub Test Plan",
    content: "# Signal Hub Verification\n\n## Load Testing\n- Simulate 10,000+ concurrent WebSocket connections.\n- Measure latency for message broadcasting (Target < 50ms).\n\n## Resilience\n- Test Redis failover during high message volume.",
    mimeType: "text/markdown"
};

-- Master Workflow (Signal)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:signal,
    sdlc_phase: "maintenance",
    name: "project-workflow-status",
    title: "Master Workflow: Kyx Signal",
    content: "# Master Workflow: Kyx Signal\n\n## Status: In Design\n\n- [x] PLAN: PRD (Complete)\n- [/] DESIGN: Architecture & Protocol (In Progress)\n- [ ] IMPLEMENTATION: Pub/Sub Logic (Pending)\n- [x] VERIFICATION: Test Plan (Draft Complete)",
    mimeType: "text/markdown"
};

COMMIT TRANSACTION;
