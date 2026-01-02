USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- Approved Tech Stack
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:global,
    sdlc_phase: "planning",
    name: "approved-tech-stack",
    title: "Global: Approved Technology Stack",
    content: "# Approved Technology Stack for Kyx Ecosystem\n\nThis document outlines the **Standardized Technology Stack** authorized for use across all Kyx projects. Any deviation requires explicit approval.\n\n## 1. Frontend & Web\n- **Framework**: SvelteKit (Preferred), Svelte 5\n- **Runtime/Bundler**: Bun (Preferred for local dev/scripts)\n- **Languages**: TypeScript (Strict), JavaScript, CSS\n- **Styling**: TailwindCSS (Standard), Vanilla CSS (For critical path)\n\n## 2. Backend & Systems\n- **Core Performance**: Rust (with Ntex framework) - *Primary for High Performance*\n- **Scripting/Data**: Python - *AI/Data Science workloads*\n- **Microservices**: Go - *Specific utility services*\n- **Runtime**: Docker (Debian Slim for production)\n\n## 3. Databases & Storage\n- **Relational**: PostgreSQL (Primary Transactional DB)\n- **Legacy/Support**: MySQL\n- **Caching/Queue**: Redis\n- **Multi-model**: SurrealDB (Governance Hub)\n\n## 4. External MCP Servers (Sidecar)\nThese servers are authorized to be installed alongside `kyx-governance` for specialized tasks:\n- **Svelte MCP**: `https://mcp.svelte.dev/mcp`\n- **Postgres MCP**: (Community Standard)\n\n## Usage Rule\nAll AI Agents must verify if a proposed tool is in this list before recommending it. If a tool is not listed (e.g., PHP, Java), it is **NOT AUTHORIZED** by default.",
    mimeType: "text/markdown"
};

-- Architecture Templates
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:global,
    sdlc_phase: "design",
    name: "standard-architecture-templates",
    title: "Standard Project Structures (DDD/Clean)",
    content: "# Standard Project Structures\nAll Kyx projects MUST follow these Clean Architecture / DDD patterns relative to their language.\n\n## 1. Rust (System/Backends)\n**Pattern**: Modular Monolith with Workspace or Clean Architecture.\n```text\n/src\n  /core          # Shared Kernel (Config, Logger, Setup) -> \"Dynamic Core\"\n  /modules       # DDD Modules (User, Auth, Payment)\n    /domain      # Entities, Ports (Traits), Rules (Pure Rust)\n    /usecase     # Business Logic (Interactors)\n    /infra       # Adapters (SurrealDB, Redis, API Clients)\n  /main.rs       # Wiring & Bootstrapping\n```\n\n## 2. SvelteKit (Frontend)\n**Pattern**: Feature-based + Clean UI.\n```text\n/src\n  /lib\n    /components  # Shared UI Components (Atomic)\n    /features    # Feature-specific logic & components\n      /auth\n      /billing\n    /server      # Server-side logic (Actions/Loaders)\n    /stores      # Global State Management\n/routes          # File-based Routing (Keep logic minimal here, delegate to /lib)\n```\n\n## 3. Python (AI/Data)\n**Pattern**: Clean Architecture.\n```text\n/src\n  /app\n    /core        # Settings, Security\n    /domain      # Models\n    /services    # Business Logic\n    /api         # FastAPI Routers\n/tests\n```\n\n## 4. Go (Microservices)\n**Pattern**: Standard Go Layout.\n```text\n/cmd             # Entry points\n/internal        # Private application code\n  /domain        # Business objects\n  /service       # Logic\n  /repository    # Data Access\n/pkg             # Public libraries (Shared code)\n```",
    mimeType: "text/markdown"
};

-- Dynamic Core Concept
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:global,
    sdlc_phase: "design",
    name: "dynamic-core-concept",
    title: "Concept: Dynamic Core & Metadata-Driven Architecture",
    content: "# Dynamic Core Architecture\n\n## Philosophy\n\"Build the Engine, Configure the Logic.\"\nInstead of hardcoding business rules, valid values, or workflows into the binary, we store them as **Metadata** in the database (SurrealDB). The Application (Core) acts as an interpreter/executor of this metadata.\n\n## Mechanism\n1.  **The Core (Rust/Go)**:\n    - Immutable, high-performance engine.\n    - Handles I/O, Connections, Security, and \"Execution\".\n    - Does NOT contain volatile business rules.\n2.  **The Brain (Database)**:\n    - Stores `ai_rules`, `workflows`, `configuration`, and `ui_layouts`.\n    - Example: Instead of hardcoding a \"Tax Rate\", query it. Instead of hardcoding \"Incident Steps\", read the Workflow definition.\n3.  **Shared Components**:\n    - Common libraries (e.g., `kyx-auth-crate`) used by all services.\n    - Centralized UI Components (Svelte Lib) used by all frontends.\n\n## Benefits\n- **Agility**: Change logic instantly without recompiling/redeploying.\n- **Consistency**: All services share the same \"Brain\".\n- **Governance**: Rules can be audited and managed centrally.",
    mimeType: "text/markdown"
};

-- Coding Standards
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:global,
    sdlc_phase: "implementation",
    name: "coding-standards",
    title: "Eco-system Coding Standards",
    content: "# Global Coding Standards\n\n1. Use Rust where performance is critical.\n2. All APIs must be documented via MCP.",
    mimeType: "text/markdown"
};

COMMIT TRANSACTION;
