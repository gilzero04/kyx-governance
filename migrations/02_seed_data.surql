USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- ==========================================
-- 1. PROJECTS (Upsert)
-- ==========================================

-- Global
DELETE mcp_projects WHERE name = 'kyx-global';
LET $global = (CREATE mcp_projects CONTENT { 
    name: "kyx-global", 
    description: "Organization-wide Governance Standards", 
    active: true 
});
LET $global_id = $global[0].id;

-- Kernel
DELETE mcp_projects WHERE name = 'kyx-kernel';
LET $kernel = (CREATE mcp_projects CONTENT { 
    name: "kyx-kernel", 
    description: "Core Engine Project", 
    active: true 
});
LET $kernel_id = $kernel[0].id;

-- MCP
DELETE mcp_projects WHERE name = 'kyx-governance';
LET $mcp = (CREATE mcp_projects CONTENT { 
    name: "kyx-governance", 
    description: "Kyx MCP Server Project", 
    active: true 
});
LET $mcp_id = $mcp[0].id;

-- ==========================================
-- 2. CLEANUP (Tools, Rules, Docs, Incidents)
-- ==========================================
-- We clean everything to ensure a fresh, consistent state based on this file.
DELETE mcp_tool;
DELETE ai_rules;
DELETE mcp_documentation;
DELETE mcp_incident;

-- ==========================================
-- 3. TOOLS (Static & Dynamic)
-- ==========================================

-- Search Governance
CREATE mcp_tool CONTENT {
    name: "search-governance",
    title: "Search Governance",
    description: "Search across all governance documents and rules.",
    input_schema: {
        "type": "object",
        "properties": {
            "query": { "type": "string" }
        },
        "required": ["query"]
    },
    enabled: true,
    execution_type: 'static',
    parameter_map: {},
    sql_template: "",
    project_id: $mcp_id
};

-- List Projects
CREATE mcp_tool CONTENT {
    name: "list-projects",
    title: "List Projects",
    description: "Returns a list of all active projects in the Kyx ecosystem.",
    input_schema: {
        "type": "object",
        "properties": {},
        "required": []
    },
    enabled: true,
    execution_type: 'static',
    parameter_map: {},
    sql_template: "",
    project_id: $mcp_id
};

-- List Documents
CREATE mcp_tool CONTENT {
    name: "list-documents",
    title: "List Documents",
    description: "Returns an index of all SDLC documentation.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string" }
        },
        "required": []
    },
    enabled: true,
    execution_type: 'static',
    parameter_map: {},
    sql_template: "",
    project_id: $mcp_id
};

-- List Tech Stack
CREATE mcp_tool CONTENT {
    name: "list-tech-stack",
    title: "List Tech Stack",
    description: "Returns the approved languages, frameworks, and tools.",
    input_schema: {
        "type": "object",
        "properties": {},
        "required": []
    },
    enabled: true,
    execution_type: 'static',
    parameter_map: {},
    sql_template: "",
    project_id: $mcp_id
};

-- Count Incidents (Dynamic)
CREATE mcp_tool CONTENT {
    name: "count-incidents",
    title: "Count Incidents",
    description: "Dynamically counts incidents based on status.",
    input_schema: {
        "type": "object",
        "properties": {
            "status": { "type": "string" }
        },
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT count() FROM mcp_incident WHERE ($status IS NONE OR status = $status) GROUP ALL",
    parameter_map: {
        "status": "status"
    },
    project_id: $mcp_id
};

-- Report Incident (Dynamic)
CREATE mcp_tool CONTENT {
    name: "report-incident",
    title: "Report Incident",
    description: "Records a new incident directly into the governance database.",
    input_schema: {
        "type": "object",
        "properties": {
            "title": { "type": "string" },
            "symptom": { "type": "string" },
            "status": { "type": "string" },
            "project": { "type": "string" },
            "language": { "type": "string" }
        },
        "required": ["title", "project"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    -- Note: Ensure project_id is handled correctly by the handler or SQL. 
    -- For simplicity, we assume string inputs for now, but in a real app we'd lookup ID.
    sql_template: "CREATE mcp_incident CONTENT { title: $title, symptom: $symptom, status: $status, project_id: (SELECT id FROM mcp_projects WHERE name = $project)[0].id, programming_language: $language, created_at: time::now() }",
    parameter_map: {
        "title": "title",
        "symptom": "symptom",
        "status": "status",
        "project": "project",
        "language": "language"
    },
    project_id: $mcp_id
};


-- ==========================================
-- 4. RULES (Consolidated)
-- ==========================================

-- P100: Coding
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 100,
    content: "All code must be self-documenting and follow project-specific linting rules."
};

-- P98: Quality & Change Control
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 98,
    content: "Rule: Quality Assurance & Change Control.\n1. VERIFY FIRST: Never finish a task without running tests/lints/checks.\n2. FIX ISSUES: Solve all errors found during verification. Do not ignore warnings.\n3. CONSISTENCY: Stick to existing tools/patterns.\n4. CONSENT: You must ASK PERMISSION and explain 'Why' before adding new tools or changing architectures."
};

-- P97: SAFETY / BACKUP (NEW REQUEST)
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 97,
    content: "Rule: Safety & Backup.\n1. BACKUP FIRST: Before editing any critical file or data, ensure a backup exists or use version control to commit the current state.\n2. MIGRATION SAFETY: When modifying database schemas or data, always ensure existing data is preserved or safely migrated.\n3. CLEANUP PROTOCOL: Once changes are verified and functioning correctly, YOU MUST ASK the user for permission to delete the backup files to keep the workspace clean."
};

-- P95: Incident Protocol
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 95,
    content: "Operational Rule: Incident Protocol. When encountering a problem/error: 1. SEARCH mcp_incident within the CURRENT project_id. 2. IF NOT FOUND locally, SEARCH GLOBALLY across all projects. 3. IF FOUND (Local or Global), apply the solution. 4. IF NOT FOUND, analyze root cause and RECORD a new entry in mcp_incident with: title, symptom, root_cause, solution, project_id, programming_language. 5. MANDATORY: Always set and report 'status' (solved/unsolved/investigating)."
};

-- P90: Security
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 90,
    content: "Rule: Secure Secrets Generation.\n1. COMPLEXITY: Passwords/Secrets must be 32+ bytes with high entropy.\n2. CLEANLINESS: To ensure connection string compatibility, MUST NOT use: whitespace or characters @ : / ? # [ ] \\ ' \" $"
};

-- P88: Navigation
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 88,
    content: "Rule: Navigation & Tool Usage.\n    1. WHERE TO LOOK:\n       - For Rules/Standards -> Use `search_governance` with query 'rule' or 'standard'.\n       - For System Architecture -> Read `kyx://<project>/design/architecture`.\n       - For API Details -> Read `kyx://<project>/implementation/api-reference`.\n       - For Past Issues -> Use `search_governance` to search Incidents.\n    2. WHAT TOOL TO USE:\n       - To Find Information -> `search_governance` (Primary Knowledge Tool).\n       - To Read Documents -> `resources/read` (Deep Dive).\n    3. PROTOCOL: Always 'Search' before asking."
};

-- P85: Documentation Standards
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 85,
    content: "Rule: Documentation Standards.\n1. CONTEXT: Every document MUST belong to a 'project_id'.\n2. SCHEMA DOCS: Must detail Field Names, Data Types, Constraints (Required/Default), and Relationships (PK/FK). No ambiguity allowed."
};

-- P82: Architecture Compliance
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 82,
    content: "Rule: Architecture Compliance.\n    1. STRUCTURE: Usage of standard templates (Rust/Svelte/etc) defined in `standard-architecture-templates` is MANDATORY.\n    2. REUSE: Always look for existing Shared Components (in `pkg`, `crate`, or `lib`) before coding from scratch.\n    3. DYNAMIC FIRST: If Logic is likely to change (e.g., pricing, rules, workflows), DO NOT hardcode it. Move it to the Database/Config."
};

-- P80: PDCA Workflow
CREATE ai_rules CONTENT {
    type: "global",
    project_id: $global_id,
    priority: 80,
    content: "Rule: PDCA Workflow.\nEvery project MUST maintain a 'Master Workflow' document that tracks lifecycle artifacts:\n- PLAN: PRD, Architecture, Schema.\n- DO: Guides, Standards.\n- CHECK: Test Plans, Verification Reports.\n- ACT: Deployment, Maintenance, Incidents.\nUpdate this document continuously; never delete it."
};

-- P50: Kernel Rules
CREATE ai_rules CONTENT {
    type: "project",
    project_id: $kernel_id,
    priority: 50,
    content: "Kyx Kernel uses Rust/Ntex. Prefer functional patterns over imperative ones."
};

-- ==========================================
-- 5. DOCUMENTATION (Consolidated & Full)
-- ==========================================

-- KYX-GLOBAL

-- Approved Tech Stack
CREATE mcp_documentation CONTENT {
    project_id: $global_id,
    sdlc_phase: "planning",
    name: "approved-tech-stack",
    title: "Global: Approved Technology Stack",
    content: "# Approved Technology Stack for Kyx Ecosystem\n\nThis document outlines the **Standardized Technology Stack** authorized for use across all Kyx projects. Any deviation requires explicit approval.\n\n## 1. Frontend & Web\n- **Framework**: SvelteKit (Preferred), Svelte 5\n- **Runtime/Bundler**: Bun (Preferred for local dev/scripts)\n- **Languages**: TypeScript (Strict), JavaScript, CSS\n- **Styling**: TailwindCSS (Standard), Vanilla CSS (For critical path)\n\n## 2. Backend & Systems\n- **Core Performance**: Rust (with Ntex framework) - *Primary for High Performance*\n- **Scripting/Data**: Python - *AI/Data Science workloads*\n- **Microservices**: Go - *Specific utility services*\n- **Runtime**: Docker (Debian Slim for production)\n\n## 3. Databases & Storage\n- **Relational**: PostgreSQL (Primary Transactional DB)\n- **Legacy/Support**: MySQL\n- **Caching/Queue**: Redis\n- **Multi-model**: SurrealDB (Governance Hub)\n\n## 4. External MCP Servers (Sidecar)\nThese servers are authorized to be installed alongside `kyx-governance` for specialized tasks:\n- **Svelte MCP**: `https://mcp.svelte.dev/mcp`\n- **Postgres MCP**: (Community Standard)\n\n## Usage Rule\nAll AI Agents must verify if a proposed tool is in this list before recommending it. If a tool is not listed (e.g., PHP, Java), it is **NOT AUTHORIZED** by default.",
    mimeType: "text/markdown"
};

-- Architecture Templates
CREATE mcp_documentation CONTENT {
    project_id: $global_id,
    sdlc_phase: "design",
    name: "standard-architecture-templates",
    title: "Standard Project Structures (DDD/Clean)",
    content: "# Standard Project Structures\nAll Kyx projects MUST follow these Clean Architecture / DDD patterns relative to their language.\n\n## 1. Rust (System/Backends)\n**Pattern**: Modular Monolith with Workspace or Clean Architecture.\n```text\n/src\n  /core          # Shared Kernel (Config, Logger, Setup) -> \"Dynamic Core\"\n  /modules       # DDD Modules (User, Auth, Payment)\n    /domain      # Entities, Ports (Traits), Rules (Pure Rust)\n    /usecase     # Business Logic (Interactors)\n    /infra       # Adapters (SurrealDB, Redis, API Clients)\n  /main.rs       # Wiring & Bootstrapping\n```\n\n## 2. SvelteKit (Frontend)\n**Pattern**: Feature-based + Clean UI.\n```text\n/src\n  /lib\n    /components  # Shared UI Components (Atomic)\n    /features    # Feature-specific logic & components\n      /auth\n      /billing\n    /server      # Server-side logic (Actions/Loaders)\n    /stores      # Global State Management\n/routes          # File-based Routing (Keep logic minimal here, delegate to /lib)\n```\n\n## 3. Python (AI/Data)\n**Pattern**: Clean Architecture.\n```text\n/src\n  /app\n    /core        # Settings, Security\n    /domain      # Models\n    /services    # Business Logic\n    /api         # FastAPI Routers\n/tests\n```\n\n## 4. Go (Microservices)\n**Pattern**: Standard Go Layout.\n```text\n/cmd             # Entry points\n/internal        # Private application code\n  /domain        # Business objects\n  /service       # Logic\n  /repository    # Data Access\n/pkg             # Public libraries (Shared code)\n```",
    mimeType: "text/markdown"
};

-- Dynamic Core Concept
CREATE mcp_documentation CONTENT {
    project_id: $global_id,
    sdlc_phase: "design",
    name: "dynamic-core-concept",
    title: "Concept: Dynamic Core & Metadata-Driven Architecture",
    content: "# Dynamic Core Architecture\n\n## Philosophy\n\"Build the Engine, Configure the Logic.\"\nInstead of hardcoding business rules, valid values, or workflows into the binary, we store them as **Metadata** in the database (SurrealDB). The Application (Core) acts as an interpreter/executor of this metadata.\n\n## Mechanism\n1.  **The Core (Rust/Go)**:\n    - Immutable, high-performance engine.\n    - Handles I/O, Connections, Security, and \"Execution\".\n    - Does NOT contain volatile business rules.\n2.  **The Brain (Database)**:\n    - Stores `ai_rules`, `workflows`, `configuration`, and `ui_layouts`.\n    - Example: Instead of hardcoding a \"Tax Rate\", query it. Instead of hardcoding \"Incident Steps\", read the Workflow definition.\n3.  **Shared Components**:\n    - Common libraries (e.g., `kyx-auth-crate`) used by all services.\n    - Centralized UI Components (Svelte Lib) used by all frontends.\n\n## Benefits\n- **Agility**: Change logic instantly without recompiling/redeploying.\n- **Consistency**: All services share the same \"Brain\".\n- **Governance**: Rules can be audited and managed centrally.",
    mimeType: "text/markdown"
};

-- Coding Standards
CREATE mcp_documentation CONTENT {
    project_id: $global_id,
    sdlc_phase: "implementation",
    name: "coding-standards",
    title: "Eco-system Coding Standards",
    content: "# Global Coding Standards\n\n1. Use Rust where performance is critical.\n2. All APIs must be documented via MCP.",
    mimeType: "text/markdown"
};


-- KYX-KERNEL

-- API Spec
CREATE mcp_documentation CONTENT {
    project_id: $kernel_id,
    sdlc_phase: "design",
    name: "api-spec",
    title: "Kernel API Specification",
    content: "# Kernel API Spec\n\n## v1.0\nEndpoints for dynamic tool dispatching...",
    mimeType: "text/markdown"
};


-- KYX-MCP

-- PRD
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "planning",
    name: "prd",
    title: "Product Requirement Document",
    content: "# Kyx MCP Server PRD\n\n## Objective\nCreate a Model Context Protocol (MCP) server to act as a centralized governance hub for the Kyx ecosystem.\n\n## Core Features\n1. **Governance Search**: Allow AI agents to search for rules and standards.\n2. **Context Provider**: Provide projects-specific context (tech stack, active phase).\n3. **Rule Enforcement**: Inject mandatory rules into agent context.\n\n## Success Metrics\n- Response time < 200ms\n- 100% availability of governance rules",
    mimeType: "text/markdown"
};

-- Architecture
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "design",
    name: "architecture",
    title: "System Architecture",
    content: "# System Architecture\n\n## Tech Stack\n- **Language**: Rust (Edition 2024)\n- **Web Framework**: Ntex (High performance async)\n- **Database**: SurrealDB (Multi-model)\n- **Runtime**: Docker (Debian Slim)\n\n## Components\n1. **HTTP Server**: Handles JSON-RPC 2.0 requests at `/mcp`.\n2. **Database Layer**: Direct connection to SurrealDB via `surrealdb` crate.\n3. **MCP Core**: Handles protocol messages (initialize, tools/list, resources/read).",
    mimeType: "text/markdown"
};

-- Rust Standards
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "implementation",
    name: "rust-standards",
    title: "Rust Coding Standards",
    content: "# Rust Coding Standards for Kyx MCP\n\n1. **Async Runtime**: Use `ntex::rt` for valid async operations.\n2. **Error Handling**: Use `anyhow::Result` for application logic.\n3. **Logging**: Use `log` facade with `env_logger`. DO NOT use `println!` except for critical startup sequence.\n4. **Database**: Use structured `serde` structs for all DB interactions.",
    mimeType: "text/markdown"
};

-- Test Plan
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "verification",
    name: "test-plan",
    title: "Test Plan",
    content: "# Verification Plan\n\n## Unit Tests\n- Run `cargo test` to verify logic in `src/modules`.\n\n## Integration Tests\n- Verify `GET /health` returns 200.\n- Verify `POST /mcp` with `initialize` returns capabilities.\n- Verify `POST /mcp` with `tools/list` returns `search_governance`.\n\n## Manual Verification\n- Use `curl` to simulate agent interactions.\n- Verify SurrealDB data persistence.",
    mimeType: "text/markdown"
};

-- Deployment Trigger
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "maintenance",
    name: "deployment",
    title: "Deployment Guide",
    content: "# Deployment Guide\n\n## Docker\nBuild and run using Docker Compose:\n```bash\ndocker compose up -d --build\n```\n\n## Environment Variables\n- `PORT`: 3001\n- `mcp_api_key`: Secret key for Bearer auth.\n- `SURREAL_URL`: WebSocket URL for DB.\n- `RUST_LOG`: Set to `info` or `debug`.",
    mimeType: "text/markdown"
};

-- API Reference
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "implementation",
    name: "api-reference",
    title: "Kyx MCP API Reference & Usage Guide",
    content: "# Kyx MCP API Reference\n\n## Authentication\nAll requests MUST include the `Authorization` header with a valid Bearer token.\n`Authorization: Bearer <MCP_API_KEY>`\n\n## Endpoints\n\n### 1. Health Check\n- **URL**: `GET /health`\n- **Response**: `200 OK` (Application is running)\n\n### 2. MCP JSON-RPC\n- **URL**: `POST /mcp`\n- **Content-Type**: `application/json`\n- **Description**: Main entry point for all Agent-Server interactions.\n\n#### Supported Methods:\n\n**A. Initialize**\n- **Method**: `initialize`\n- **Usage**: Handshake to exchange capabilities.\n```json\n{ \"jsonrpc\": \"2.0\", \"method\": \"initialize\", \"id\": 1, \"params\": { ... } }\n```\n\n**B. List Tools**\n- **Method**: `tools/list`\n- **Usage**: Discover available tools.\n- **Tools Available**: `search_governance` (Searches Docs & Incidents).\n\n**C. List Resources**\n- **Method**: `resources/list`\n- **Usage**: discover available documentation resources.\n- **URI Format**: `kyx://<project>/<phase>/<name>`\n\n**D. Read Resource**\n- **Method**: `resources/read`\n- **Params**: `{\"uri\": \"kyx://kyx-governance/design/architecture\"}`\n- **Usage**: Read content of a specific document.\n\n**E. Call Tool**\n- **Method**: `tools/call`\n- **Name**: `search_governance`\n- **Params**: `{\"name\": \"search_governance\", \"arguments\": {\"query\": \"database\"}}`\n- **Usage**: Execute a tool.\n\n## Usage Guide\n1. **Search First**: Always use `search_governance` to look for existing rules or solutions.\n2. **Read Context**: Use `resources/read` to get full details of a project's architecture or standards.\n3. **Execute**: Perform tasks based on the retrieved rules.",
    mimeType: "text/markdown"
};

-- Master Workflow
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "maintenance",
    name: "project-workflow-status",
    title: "Master Workflow: Kyx MCP (PDCA Tracking)",
    content: "# Master Workflow: Kyx MCP\n**Status**: Maintenance / Optimization\n**Last Updated**: 2026-01-02\n\n## 1. PLAN (Completed)\n- [x] **Product Requirements**: `planning/prd` (Complete)\n- [x] **Architecture**: `design/architecture` (Complete)\n- [x] **Schema Design**: `design/schema-full-dictionary` (Complete)\n- [x] **Incident Schema**: `design/schema-incident-tracking` (Complete)\n\n## 2. DO (Completed)\n- [x] **Rust Standards**: `implementation/rust-standards` (Complete)\n- [x] **Global Standards**: `implementation/coding-standards` (Inherited from Global)\n\n## 3. CHECK (Completed)\n- [x] **Test Plan**: `verification/test-plan` (Complete)\n- [x] **Verification**: *See system walkthrough artifact*\n\n## 4. ACT (Ongoing)\n- [x] **Deployment Guide**: `maintenance/deployment` (Complete)\n- [/] **Incident Logs**: `mcp_incident` Table (Active - Self-healing enabled)\n\n## Next Steps\n- Monitor integration with other agents.\n- Expand toolset based on user feedback.\n",
    mimeType: "text/markdown"
};

-- Schema Incident Tracking
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "design",
    name: "schema-incident-tracking",
    title: "Database Schema: Incident Tracking (mcp_incident)",
    content: "# Table: `mcp_incident` (Incident Tracking)\n\n## Purpose\nStores records of technical issues, bugs, and operational incidents encountered during the development and maintenance of the Kyx ecosystem.\n\n## Schema Definition\n\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Unique (e.g., `mcp_incident:ul5...`). |\n| `project_id` | record<mcp_projects> | Yes | Link to the specific project (e.g. `kyx-governance`). |\n| `programming_language` | string | No | The primary language involved (e.g. `Rust`, `TypeScript`). |\n| `title` | string | Yes | concise summary of the problem. |\n| `symptom` | string | Yes | Detailed description, error messages, stack traces. |\n| `root_cause` | string | No | Technical explanation of *why* it occurred. |\n| `solution` | string | No | Steps taken to resolve the issue. |\n| `status` | string | Yes | `['identified', 'investigating', 'solved', 'mitigated', 'wont-fix']`. | \n| `status_detail` | string | No | Additional context. |\n| `created_at` | datetime | Yes | Timestamp. |\n\n## Usage Guidelines\n\n1. **Search First**: Before attempting a fix, always search this table.\n2. **Context**: Always specify `project_id` and `programming_language` to help filter relevance.",
    mimeType: "text/markdown"
};

-- Schema Full Dictionary
CREATE mcp_documentation CONTENT {
    project_id: $mcp_id,
    sdlc_phase: "design",
    name: "schema-full-dictionary",
    title: "Database Schema: Data Dictionary",
    content: "# Database Schema Data Dictionary\n\nThis document details the schema for all tables in the `kyx/governance` database as of version 1.1.\n\n## Overview\nSurrealDB is a schemafull/schemaless hybrid. We strictly enforce schemas.\n\n---\n\n## 1. `mcp_projects` (Projects)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_projects:<uuid>` |\n| `name` | string | Yes | Unique project identifier. |\n| `description` | string | No | Human-readable description. |\n| `active` | bool | Yes | Soft-delete flag. |\n\n---\n\n## 2. `ai_rules` (Governance Rules)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `ai_rules:<uuid>` |\n| `type` | string | Yes | Scope: `global` or `project`. |\n| `priority` | int | Yes | Injection order. |\n| `content` | string | Yes | Rule text. |\n\n---\n\n## 3. `mcp_documentation` (Knowledge Base)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_documentation:<uuid>` |\n| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |\n| `sdlc_phase` | string | Yes | Phase. |\n| `name` | string | Yes | URL-safe slug. |\n| `title` | string | Yes | Human-readable title. |\n| `content` | string | Yes | Markdown content. |\n\n---\n\n## 4. `mcp_tool` (Capabilities)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_tool:<uuid>` |\n| `name` | string | Yes | Unique ID. |\n| `input_schema` | object | Yes | JSON Schema. |\n\n---\n\n## 5. `mcp_incident` (Incident Tracking)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_incident:<uuid>` |\n| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |\n| `programming_language` | string | No | e.g., `Rust`, `TypeScript`. |\n| `title` | string | Yes | Short summary. |\n| `symptom` | string | Yes | Description of error. |\n| `status` | string | Yes | Status enum. |",
    mimeType: "text/markdown"
};

-- ==========================================
-- 6. INCIDENTS (Restored + Sample)
-- ==========================================

-- Historical: Connection String Parsing
CREATE mcp_incident CONTENT {
    title: "Connection string parsing error due to special characters in password",
    symptom: "SurrealDB client fails to connect or throws 'Parse error' when using generated passwords in connection strings.",
    root_cause: "Certain special characters (e.g. @, :, /, #) have reserved meanings in URI/URL syntax.",
    solution: "Define a strict character set for generated passwords that excludes URI-reserved characters. Update the AI Global Rule to prohibit: @, :, /, ?, #, [, ], backslash, single quote, double quote, $, and whitespace.",
    status: "solved",
    status_detail: "Implemented Global Rule (Priority 90) to enforce clean password generation.",
    project_id: $mcp_id,
    created_at: time::now()
};

-- Sample: System Initialization
CREATE mcp_incident CONTENT {
    title: "System Initialization Verification",
    symptom: "User verification of database persistence stability.",
    root_cause: "Routine system check.",
    solution: "Confrmed availability of all tables and tools.",
    status: "solved",
    project_id: $mcp_id,
    programming_language: "Rust",
    created_at: time::now()
};

COMMIT TRANSACTION;
