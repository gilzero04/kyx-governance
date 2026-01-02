# Project Governance Report: kyx-governance

> Generated at: 2026-01-02T11:55:11.448686667Z

---

## 📄 Documentation

### System Architecture
# System Architecture

## Tech Stack
- **Language**: Rust (Edition 2024)
- **Web Framework**: Ntex (High performance async)
- **Database**: SurrealDB (Multi-model)
- **Runtime**: Docker (Debian Slim)

## Components
1. **HTTP Server**: Handles JSON-RPC 2.0 requests at `/mcp`.
2. **Remote Proxy**: Secure interface for external agent connectivity.
3. **Database Layer**: Direct connection to SurrealDB via `surrealdb` crate.
4. **MCP Core**: Handles protocol messages (initialize, tools/list, resources/read).

### Database Schema: Data Dictionary
# Database Schema Data Dictionary

This document details the schema for all tables in the `kyx/governance` database as of version 1.1.

## Overview
SurrealDB is a schemafull/schemaless hybrid. We strictly enforce schemas.

---

## 1. `mcp_projects` (Projects)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_projects:<uuid>` |
| `name` | string | Yes | Unique project identifier. |
| `description` | string | No | Human-readable description. |
| `active` | bool | Yes | Soft-delete flag. |

---

## 2. `ai_rules` (Governance Rules)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `ai_rules:<uuid>` |
| `type` | string | Yes | Scope: `global` or `project`. |
| `priority` | int | Yes | Injection order. |
| `content` | string | Yes | Rule text. |

---

## 3. `mcp_documentation` (Knowledge Base)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_documentation:<uuid>` |
| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |
| `sdlc_phase` | string | Yes | Phase. |
| `name` | string | Yes | URL-safe slug. |
| `title` | string | Yes | Human-readable title. |
| `content` | string | Yes | Markdown content. |

---

## 4. `mcp_tool` (Capabilities)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_tool:<uuid>` |
| `name` | string | Yes | Unique ID. |
| `input_schema` | object | Yes | JSON Schema. |

---

## 5. `mcp_incident` (Incident Tracking)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_incident:<uuid>` |
| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |
| `programming_language` | string | No | e.g., `Rust`, `TypeScript`. |
| `title` | string | Yes | Short summary. |
| `symptom` | string | Yes | Description of error. |
| `status` | string | Yes | Status enum. |

### Database Schema: Incident Tracking (mcp_incident)
# Table: `mcp_incident` (Incident Tracking)

## Purpose
Stores records of technical issues, bugs, and operational incidents encountered during the development and maintenance of the Kyx ecosystem.

## Schema Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Unique (e.g., `mcp_incident:ul5...`). |
| `project_id` | record<mcp_projects> | Yes | Link to the specific project (e.g. `kyx-governance`). |
| `programming_language` | string | No | The primary language involved (e.g. `Rust`, `TypeScript`). |
| `title` | string | Yes | concise summary of the problem. |
| `symptom` | string | Yes | Detailed description, error messages, stack traces. |
| `root_cause` | string | No | Technical explanation of *why* it occurred. |
| `solution` | string | No | Steps taken to resolve the issue. |
| `status` | string | Yes | `['identified', 'investigating', 'solved', 'mitigated', 'wont-fix']`. |
| `status_detail` | string | No | Additional context. |
| `created_at` | datetime | Yes | Timestamp. |

## Usage Guidelines

1. **Search First**: Before attempting a fix, always search this table.
2. **Context**: Always specify `project_id` and `programming_language` to help filter relevance.

### Rust Coding Standards
# Rust Coding Standards for Kyx Governance

1. **Async Runtime**: Use `ntex::rt` for valid async operations.
2. **Error Handling**: Use `anyhow::Result` for application logic.
3. **Logging**: Use `log` facade with `env_logger`. DO NOT use `println!` except for critical startup sequence.
4. **Database**: Use structured `serde` structs for all DB interactions.

### Deployment Guide
# Deployment Guide

## Docker
Build and run using Docker Compose:
```bash
docker compose up -d --build
```

## Environment Variables
- `PORT`: 3001
- `mcp_api_key`: Secret key for Bearer auth.
- `SURREAL_URL`: WebSocket URL for DB.
- `RUST_LOG`: Set to `info` or `debug`.

### Eco-system Operation & Usage Guide
# Eco-system Operation & Usage Guide

## 1. Data Persistence & Migrations
- **Nature of DB**: The governance data is metadata-driven. Any changes to files in `/migrations` (tools, rules, documentation) require the database to be re-seeded.
- **Apply Changes**: To apply new metadata or schema changes:
  ```bash
  docker compose down -v && docker compose up -d --build
  ```
  *Note: `down -v` wipes the current database volume, forcing the seeder to re-run and apply all `.surql` files in alphanumeric order.

## 2. API Reference & Documentation
- **Metadata-Hub**: All API details, connection strings (via `.env`), and project structures are stored centrally here.
- **Where to look**:
  - **API Specs**: Read `kyx://<project>/design/api-spec`.
  - **Database Schemas**: Use `list-database-schema` or read `kyx://kyx-governance/design/schema-full-dictionary`.
  - **Governance Rules**: Use `list-active-rules`.

## 3. Incident Management
- Always search incidents before starting work: `search-governance query='rule'`.
- Report new issues immediately using `report-incident`.

## 4. Remote Synchronization Protocol
- **Cycle**: DATA Hub <-> Local Snapshot (`.surql`).

### A. Download (Initial Sync / Pull)
- **Goal**: Initial setup or getting the latest from Hub.
- **Protocol**:
  1. Use `export-snapshot project='<name>'` tool to fetch current Hub state.
  2. Create/Update your local file: `knowledge_base/<project>.surql`.
  3. Format the JSON result from the tool into SurrealDB `UPSERT` or `CREATE` statements.

### B. Upload (Push / Sync)
- **Goal**: Sync your local changes back to the Hub.
- **Protocol**:
  1. Keep all changes in your local `.surql` file.
  2. Use `sync-snapshot` tool.
  3. Copy the content of your local `.surql` and paste it into the `sql_commands` argument.
- **Why?**: This allows for batch updates, ensuring atomic consistency.
- **Fallback (Curl)**: 
  ```bash
  curl -X POST http://<HUB_URL>/mcp \
       -H "Authorization: Bearer <API_KEY>" \
       -H "Content-Type": "application/json" \
       -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"sync-snapshot","arguments":{"sql_commands":"<PASTE_SQL_HERE>"}},"id":1}'
  ```


### Master Workflow: Kyx Governance Hub
# Master Workflow: Kyx Governance Hub

## Status: Operational & Organized

- [x] PLAN: Merged PRD
- [x] DESIGN: Consolidated Architecture
- [x] IMPLEMENTATION: Proxy & Hub Implementation
- [x] VERIFICATION: Stress Test & ID Parsing Fix
- [x] MAINTENANCE: Migration Refactoring (Split files)

### Kyx Governance Hub PRD
# Kyx Governance Hub PRD

## Objective
To provide a centralized Model Context Protocol (MCP) server for governance, standard enforcement, and remote proxying across the Kyx ecosystem.

## Core Features
1. **Governance Search**: Global access to rules and standards.
2. **Remote Proxy**: Secure handshake and tool relay for distributed agents.
3. **Rule Enforcement**: Dynamic injection of context-aware rules.
4. **Metadata Management**: Dynamic tool and schema definitions.

### Test Plan
# Verification Plan

## Unit Tests
- Run `cargo test` to verify logic in `src/modules`.

## Integration Tests
- Verify `GET /health` returns 200.
- Verify `POST /mcp` with `initialize` returns capabilities.
- Verify `POST /mcp` with `tools/list` returns all dynamic tools.
- Verify `POST /mcp` with `list-database-schema` returns schemas.

## Remote Tests
- Verify successful handshake and proxying of tool calls.

## ⚖️ Governance Rules

| Priority | Type | Content |
|----------|------|---------|
| 52 | project | Rule: Governance Env. All governance secrets are located in the local .env. |


## 🛡️ Incident Logs

#### Connection string parsing error due to special characters in password
- **Status**: solved
- **Language**: 
- **Symptom**: SurrealDB client fails to connect or throws 'Parse error' when using generated passwords in connection strings.
- **Resolution**: Implemented Global Rule (Priority 90) to enforce clean password generation.

#### System Initialization Verification
- **Status**: solved
- **Language**: Rust
- **Symptom**: User verification of database persistence stability.
- **Resolution**: N/A


