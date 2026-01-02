USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- PRD
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:kernel,
    sdlc_phase: "planning",
    name: "prd",
    title: "Kernel Product Requirement Document",
    content: "# Kyx Kernel PRD\n\n## Objective\nTo provide a high-performance, secure, and metadata-driven core execution engine for the Kyx ecosystem.\n\n## Core Features\n1. **Dynamic Scaling**: Handle variable workloads with Rust/Ntex.\n2. **Multi-Tenant Isolation**: Secure data separation at the engine level.\n3. **Plugin Architecture**: Support for dynamic business logic injection.",
    mimeType: "text/markdown"
};

-- Architecture
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:kernel,
    sdlc_phase: "design",
    name: "architecture",
    title: "Kernel System Architecture",
    content: "# Kyx Kernel Architecture\n\n## Layers\n1. **I/O Layer**: Ntex-based async handlers.\n2. **Security layer**: RBAC and JWT verification.\n3. **Logic Interpreter**: Executes business rules fetched from Metadata Hub.",
    mimeType: "text/markdown"
};

-- API Spec
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:kernel,
    sdlc_phase: "design",
    name: "api-spec",
    title: "Kernel API Specification",
    content: "# Kernel API Spec\n\n## v1.0\nEndpoints for dynamic tool dispatching, user management, and system monitoring.",
    mimeType: "text/markdown"
};

-- Test Plan
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:kernel,
    sdlc_phase: "verification",
    name: "test-plan",
    title: "Kernel Test Plan",
    content: "# Kernel Verification\n\n## Performance\n- Benchmarking async handlers under high load.\n\n## Security\n- Penetration testing for multi-tenant isolation.",
    mimeType: "text/markdown"
};

-- Master Workflow (Kernel)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:kernel,
    sdlc_phase: "maintenance",
    name: "project-workflow-status",
    title: "Master Workflow: Kyx Kernel",
    content: "# Master Workflow: Kyx Kernel\n\n- [x] PLAN: PRD\n- [x] DESIGN: Architecture, API Spec\n- [x] CHECK: Test Plan\n- [ ] ACT: Maintenance Manual",
    mimeType: "text/markdown"
};

COMMIT TRANSACTION;
