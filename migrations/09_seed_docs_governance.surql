USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- PRD
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "planning",
    name: "prd",
    title: "Kyx Governance Hub PRD",
    content: "# Kyx Governance Hub PRD\n\n## Objective\nTo provide a centralized Model Context Protocol (MCP) server for governance, standard enforcement, and remote proxying across the Kyx ecosystem.\n\n## Core Features\n1. **Governance Search**: Global access to rules and standards.\n2. **Remote Proxy**: Secure handshake and tool relay for distributed agents.\n3. **Rule Enforcement**: Dynamic injection of context-aware rules.\n4. **Metadata Management**: Dynamic tool and schema definitions.",
    mimeType: "text/markdown"
};

-- Architecture
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "design",
    name: "architecture",
    title: "System Architecture",
    content: "# System Architecture\n\n## Tech Stack\n- **Language**: Rust (Edition 2024)\n- **Web Framework**: Ntex (High performance async)\n- **Database**: SurrealDB (Multi-model)\n- **Runtime**: Docker (Debian Slim)\n\n## Components\n1. **HTTP Server**: Handles JSON-RPC 2.0 requests at `/mcp`.\n2. **Remote Proxy**: Secure interface for external agent connectivity.\n3. **Database Layer**: Direct connection to SurrealDB via `surrealdb` crate.\n4. **MCP Core**: Handles protocol messages (initialize, tools/list, resources/read).",
    mimeType: "text/markdown"
};

-- Operation & Usage Guide
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "maintenance",
    name: "operation-guide",
    title: "Eco-system Operation & Usage Guide",
    content: "# Eco-system Operation & Usage Guide\n\n## 1. Data Persistence & Migrations\n- **Nature of DB**: The governance data is metadata-driven. Any changes to files in `/migrations` (tools, rules, documentation) require the database to be re-seeded.\n- **Apply Changes**: To apply new metadata or schema changes:\n  ```bash\n  docker compose down -v && docker compose up -d --build\n  ```\n  *Note: `down -v` wipes the current database volume, forcing the seeder to re-run and apply all `.surql` files in alphanumeric order.\n\n## 2. API Reference & Documentation\n- **Metadata-Hub**: All API details, connection strings (via `.env`), and project structures are stored centrally here.\n- **Where to look**:\n  - **API Specs**: Read `kyx://<project>/design/api-spec`.\n  - **Database Schemas**: Use `list-database-schema` or read `kyx://kyx-governance/design/schema-full-dictionary`.\n  - **Governance Rules**: Use `list-active-rules`.\n\n## 3. Incident Management\n- Always search incidents before starting work: `search-governance query='rule'`.\n- Report new issues immediately using `report-incident`.\n\n## 4. Remote Synchronization Protocol\n- **Cycle**: DATA Hub <-> Local Snapshot (`.surql`).\n\n### A. Download (Initial Sync / Pull)\n- **Goal**: Initial setup or getting the latest from Hub.\n- **Protocol**:\n  1. Use `export-snapshot project='<name>'` tool to fetch current Hub state.\n  2. Create/Update your local file: `knowledge_base/<project>.surql`.\n  3. Format the JSON result from the tool into SurrealDB `UPSERT` or `CREATE` statements.\n\n### B. Upload (Push / Sync)\n- **Goal**: Sync your local changes back to the Hub.\n- **Protocol**:\n  1. Keep all changes in your local `.surql` file.\n  2. Use `sync-snapshot` tool.\n  3. Copy the content of your local `.surql` and paste it into the `sql_commands` argument.\n- **Why?**: This allows for batch updates, ensuring atomic consistency.\n- **Fallback (Curl)**: \n  ```bash\n  curl -X POST http://<HUB_URL>/mcp \\\n       -H \"Authorization: Bearer <API_KEY>\" \\\n       -H \"Content-Type\": \"application/json\" \\\n       -d '{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"sync-snapshot\",\"arguments\":{\"sql_commands\":\"<PASTE_SQL_HERE>\"}},\"id\":1}'\n  ```\n",
    mimeType: "text/markdown"
};

-- Rust Standards
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "implementation",
    name: "rust-standards",
    title: "Rust Coding Standards",
    content: "# Rust Coding Standards for Kyx Governance\n\n1. **Async Runtime**: Use `ntex::rt` for valid async operations.\n2. **Error Handling**: Use `anyhow::Result` for application logic.\n3. **Logging**: Use `log` facade with `env_logger`. DO NOT use `println!` except for critical startup sequence.\n4. **Database**: Use structured `serde` structs for all DB interactions.",
    mimeType: "text/markdown"
};

-- Test Plan
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "verification",
    name: "test-plan",
    title: "Test Plan",
    content: "# Verification Plan\n\n## Unit Tests\n- Run `cargo test` to verify logic in `src/modules`.\n\n## Integration Tests\n- Verify `GET /health` returns 200.\n- Verify `POST /mcp` with `initialize` returns capabilities.\n- Verify `POST /mcp` with `tools/list` returns all dynamic tools.\n- Verify `POST /mcp` with `list-database-schema` returns schemas.\n\n## Remote Tests\n- Verify successful handshake and proxying of tool calls.",
    mimeType: "text/markdown"
};

-- Deployment Guide
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "maintenance",
    name: "deployment",
    title: "Deployment Guide",
    content: "# Deployment Guide\n\n## Docker\nBuild and run using Docker Compose:\n```bash\ndocker compose up -d --build\n```\n\n## Environment Variables\n- `PORT`: 3001\n- `mcp_api_key`: Secret key for Bearer auth.\n- `SURREAL_URL`: WebSocket URL for DB.\n- `RUST_LOG`: Set to `info` or `debug`.",
    mimeType: "text/markdown"
};


-- Master Workflow
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "maintenance",
    name: "project-workflow-status",
    title: "Master Workflow: Kyx Governance Hub",
    content: "# Master Workflow: Kyx Governance Hub\n\n## Status: Operational & Organized\n\n- [x] PLAN: Merged PRD\n- [x] DESIGN: Consolidated Architecture\n- [x] IMPLEMENTATION: Proxy & Hub Implementation\n- [x] VERIFICATION: Stress Test & ID Parsing Fix\n- [x] MAINTENANCE: Migration Refactoring (Split files)",
    mimeType: "text/markdown"
};

-- Schema Incident Tracking
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "design",
    name: "schema-incident-tracking",
    title: "Database Schema: Incident Tracking (mcp_incident)",
    content: "# Table: `mcp_incident` (Incident Tracking)\n\n## Purpose\nStores records of technical issues, bugs, and operational incidents encountered during the development and maintenance of the Kyx ecosystem.\n\n## Schema Definition\n\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Unique (e.g., `mcp_incident:ul5...`). |\n| `project_id` | record<mcp_projects> | Yes | Link to the specific project (e.g. `kyx-governance`). |\n| `programming_language` | string | No | The primary language involved (e.g. `Rust`, `TypeScript`). |\n| `title` | string | Yes | concise summary of the problem. |\n| `symptom` | string | Yes | Detailed description, error messages, stack traces. |\n| `root_cause` | string | No | Technical explanation of *why* it occurred. |\n| `solution` | string | No | Steps taken to resolve the issue. |\n| `status` | string | Yes | `['identified', 'investigating', 'solved', 'mitigated', 'wont-fix']`. |\n| `status_detail` | string | No | Additional context. |\n| `created_at` | datetime | Yes | Timestamp. |\n\n## Usage Guidelines\n\n1. **Search First**: Before attempting a fix, always search this table.\n2. **Context**: Always specify `project_id` and `programming_language` to help filter relevance.",
    mimeType: "text/markdown"
};

-- Schema Full Dictionary
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:governance,
    sdlc_phase: "design",
    name: "schema-full-dictionary",
    title: "Database Schema: Data Dictionary",
    content: "# Database Schema Data Dictionary\n\nThis document details the schema for all tables in the `kyx/governance` database as of version 1.1.\n\n## Overview\nSurrealDB is a schemafull/schemaless hybrid. We strictly enforce schemas.\n\n---\n\n## 1. `mcp_projects` (Projects)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_projects:<uuid>` |\n| `name` | string | Yes | Unique project identifier. |\n| `description` | string | No | Human-readable description. |\n| `active` | bool | Yes | Soft-delete flag. |\n\n---\n\n## 2. `ai_rules` (Governance Rules)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `ai_rules:<uuid>` |\n| `type` | string | Yes | Scope: `global` or `project`. |\n| `priority` | int | Yes | Injection order. |\n| `content` | string | Yes | Rule text. |\n\n---\n\n## 3. `mcp_documentation` (Knowledge Base)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_documentation:<uuid>` |\n| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |\n| `sdlc_phase` | string | Yes | Phase. |\n| `name` | string | Yes | URL-safe slug. |\n| `title` | string | Yes | Human-readable title. |\n| `content` | string | Yes | Markdown content. |\n\n---\n\n## 4. `mcp_tool` (Capabilities)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_tool:<uuid>` |\n| `name` | string | Yes | Unique ID. |\n| `input_schema` | object | Yes | JSON Schema. |\n\n---\n\n## 5. `mcp_incident` (Incident Tracking)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_incident:<uuid>` |\n| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |\n| `programming_language` | string | No | e.g., `Rust`, `TypeScript`. |\n| `title` | string | Yes | Short summary. |\n| `symptom` | string | Yes | Description of error. |\n| `status` | string | Yes | Status enum. |",
    mimeType: "text/markdown"
};

-- Historical: Connection String Parsing
CREATE mcp_incident CONTENT {
    title: "Connection string parsing error due to special characters in password",
    symptom: "SurrealDB client fails to connect or throws 'Parse error' when using generated passwords in connection strings.",
    root_cause: "Certain special characters (e.g. @, :, /, #) have reserved meanings in URI/URL syntax.",
    solution: "Define a strict character set for generated passwords that excludes URI-reserved characters. Update the AI Global Rule to prohibit: @, :, /, ?, #, [, ], backslash, single quote, double quote, $, and whitespace.",
    status: "solved",
    status_detail: "Implemented Global Rule (Priority 90) to enforce clean password generation.",
    project_id: mcp_projects:governance,
    created_at: time::now()
};

-- Sample: System Initialization
CREATE mcp_incident CONTENT {
    title: "System Initialization Verification",
    symptom: "User verification of database persistence stability.",
    root_cause: "Routine system check.",
    solution: "Confrmed availability of all tables and tools.",
    status: "solved",
    project_id: mcp_projects:governance,
    programming_language: "Rust",
    created_at: time::now()
};

COMMIT TRANSACTION;
