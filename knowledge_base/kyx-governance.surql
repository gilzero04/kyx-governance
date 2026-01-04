-- Kyx Governance Snapshot: kyx-governance
-- Generated at: 2026-01-04T02:16:32.749205509Z
-- Documents found: 10

USE NS kyx; USE DB governance;

BEGIN TRANSACTION;

-- 1. Documents
UPSERT mcp_documentation:wz4kx5cweruonhzwb5fh CONTENT { name: 'architecture', title: 'System Architecture', sdlc_phase: 'design', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# System Architecture

## Tech Stack
- **Language**: Rust (Edition 2024)
- **Web Framework**: Ntex (High performance async)
- **Database**: SurrealDB (Multi-model)
- **Runtime**: Docker (Debian Slim)

## Components
1. **HTTP Server**: Handles JSON-RPC 2.0 requests at `/mcp`.
2. **Remote Proxy**: Secure interface for external agent connectivity.
3. **Database Layer**: Direct connection to SurrealDB via `surrealdb` crate.
4. **MCP Core**: Handles protocol messages (initialize, tools/list, resources/read).' };
UPSERT mcp_documentation:jyckcmq08v88ybu31wul CONTENT { name: 'database-schema', title: 'Database Schema Dictionary', sdlc_phase: 'design', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Database Schema Data Dictionary

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
| `content` | string | Yes | Rule text. |' };
UPSERT mcp_documentation:u59s3n20ly876s9o8rxt CONTENT { name: 'implementation-summary', title: 'Implementation Summary', sdlc_phase: 'implementation', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Implementation Summary (Phase 3 & 4)

## Phase 3: Transition & Stabilization (2026-01-03 - 2026-01-04)
- **Objective**: Harden MCP transport and eliminate agent termination errors.
- **Actions**:
  - Reverted the experimental WebSocket transport to **Pure JSON-RPC over SSE (HTTP)**.
  - Removed 5 legacy session management tools (`create-session`, `get-session`, etc.) causing protocol conflicts.
  - Implemented **Audit Logging** (mcp_audit_log) and a dedicated `list-audit-logs` viewer tool.
  - Patched the Rust handler to correctly aggregate multi-statement SQL results (filtering `null` from `LET/BEGIN` statements).
- **Outcome**: 100% Agent stability and reliable tool execution. ✅

## Phase 4: Knowledge Base Standard (2026-01-04)
- **Objective**: Finalize export/import lifecycle and consolidate governance docs.
- **Actions**:
  - Fixed the `export-snapshot` tool to successfully export all 10 standard documents.
  - Verified the `sync-snapshot` tool for batch updates.
  - Created `.env.example` and hardened `.gitignore` for secret security.
  - Applied the final project cleanup (removed redundant logs and temporary files).
- **Outcome**: Operational Hub with a localized knowledge base fallback. ✅' };
UPSERT mcp_documentation:v29sl8okee0w3cbicze3 CONTENT { name: 'operation-guide', title: 'Eco-system Operation & Usage Guide', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Eco-system Operation & Usage Guide

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
- Always search incidents before starting work: `search-governance query=\'rule\'`.
- Report new issues immediately using `report-incident`.

## 4. Remote Synchronization Protocol
- **Cycle**: DATA Hub <-> Local Snapshot (`.surql`).' };
UPSERT mcp_documentation:nmry3112r9idv5o8b3fh CONTENT { name: 'summary-report', title: 'Summary Report', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Final Summary Report: Kyx Governance Hub Stabilization

## Project Status: OPERATIONAL (Phase 1-4 Complete)

### Accomplishments
1. **Security**: Hardened transport with Bearer token auth and secret scanning push protection.
2. **Stability**: Resolved \"Agent terminated\" errors by standardizing on MCP SSE protocol.
3. **Transparency**: Added full audit logging for all tool executions.
4. **Data Integrity**: Verified the 10-document knowledge base standard and fixed the export/import snapshot tools.

### Future Development Roadmap
1. **Real-time Monitoring**: (Phase 5) Build a dashboard for live audit logs and system metrics.
2. **Automatic Vector Updates**: Implement file watchers to auto-index documents upon change.
3. **Advanced Multi-Tenancy**: Improve project data isolation using SurrealDB IAM roles.
4. **Resilience**: Implement auto-failover to the local `.surql` snapshot if the Hub is offline.

---
**Handover Status**: The codebase at [gilzero04/kyx-governance](https://github.com/gilzero04/kyx-governance) is now in a pristine state.
**Verification Script**: [verify_sse_transport.sh](file:///Users/beykyu/Developer/kyx-tech/kyx-governance/tests/verify_sse_transport.sh) passes all checks.' };
UPSERT mcp_documentation:1zh3rrs7wx32zpypfygk CONTENT { name: 'deployment', title: 'Deployment Guide', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Deployment Guide

## Docker
Build and run using Docker Compose:
```bash
docker compose up -d --build
```

## Environment Variables
- `PORT`: 3001
- `mcp_api_key`: Secret key for Bearer auth.
- `SURREAL_URL`: WebSocket URL for DB.
- `RUST_LOG`: Set to `info` or `debug`.' };
UPSERT mcp_documentation:bjk9vkch97qmow5oez78 CONTENT { name: 'project-workflow-status', title: 'Master Workflow: Kyx Governance Hub', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Master Workflow: Kyx Governance Hub

## Status: Operational & Organized

- [x] PLAN: Merged PRD
- [x] DESIGN: Consolidated Architecture
- [x] IMPLEMENTATION: Proxy & Hub Implementation
- [x] VERIFICATION: Stress Test & ID Parsing Fix
- [x] MAINTENANCE: Migration Refactoring (Split files)' };
UPSERT mcp_documentation:5qzgyn5i94pju3n13eg8 CONTENT { name: 'test-plan', title: 'Test Plan', sdlc_phase: 'verification', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Verification Plan

## Unit Tests
- Run `cargo test` to verify logic in `src/modules`.

## Integration Tests
- Verify `GET /health` returns 200.
- Verify `POST /mcp` with `initialize` returns capabilities.
- Verify `POST /mcp` with `tools/list` returns all dynamic tools.
- Verify `POST /mcp` with `list-database-schema` returns schemas.

## Remote Tests
- Verify successful handshake and proxying of tool calls.' };
UPSERT mcp_documentation:5dmz8avxp1q7y75y4icw CONTENT { name: 'prd', title: 'Kyx Governance Hub PRD', sdlc_phase: 'planning', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Kyx Governance Hub PRD

## Objective
To provide a centralized Model Context Protocol (MCP) server for governance, standard enforcement, and remote proxying across the Kyx ecosystem.

## Core Features
1. **Governance Search**: Global access to rules and standards.
2. **Remote Proxy**: Secure interface for external agent connectivity.
3. **Rule Enforcement**: Dynamic injection of context-aware rules.
4. **Metadata Management**: Dynamic tool and schema definitions.' };
UPSERT mcp_documentation:7tmz8avxp1q7y75y4icw CONTENT { name: 'rust-standards', title: 'Rust Coding Standards', sdlc_phase: 'implementation', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Rust Coding Standards (Kyx)

## 1. Safety
- Use `unsafe` ONLY when interacting with C-libraries via FFI.
- Prefer `anyhow` for application errors and `thiserror` for library errors.

## 2. Concurrency
- Use `tokio` or `ntex` async runtimes.
- Avoid shared mutable state (use `Arc<Mutex<T>>` or `channels`).

## 3. Formatting
- Enforced via `rustfmt`.
- Max line width: 100 characters.' };

-- 2. Rules
UPSERT ai_rules:kyx_governance_deployment CONTENT { type: 'project', priority: 52, content: 'Rule: Kyx-Governance Deployment Protocol.

**CRITICAL**: kyx-governance ใช้ migrations ที่ run ตอน container start เท่านั้น!

## เมื่อแก้ไข migrations/*.surql:
1. **ต้อง Rebuild + Restart**: `docker-compose down -v && docker-compose up -d --build`
2. **ห้าม Restart อย่างเดียว**: Restart ไม่ทำให้ migrations run ใหม่
3. **ต้องลบ volumes (-v)**: เพื่อให้ database เริ่มใหม่และ run migrations

## ขั้นตอนที่ถูกต้อง:
```bash
# 1. แก้ไข migrations/XX_name.surql
# 2. Rebuild (บังคับ!)
docker-compose down -v
docker-compose up -d --build

# 3. Verify
curl http://localhost:3001/health
list-documents(project=\"kyx-governance\")
```

## เมื่อแก้ไข Rust code only:
```bash
# ไม่ต้องลบ volumes
docker-compose down
docker-compose up -d --build
```

## เมื่อใช้ MCP tools (update-document, etc):
- ไม่ต้อง rebuild
- ข้อมูลอัปเดตทันที
- ใช้สำหรับแก้ไขเนื้อหาเอกสารเท่านั้น

**REMEMBER**: migrations = rebuild + wipe volumes required!', project_id: mcp_projects:governance };
UPSERT ai_rules:56v5b8qa3kn3qxo1yntl CONTENT { type: 'project', priority: 52, content: 'Rule: Governance Env. All governance secrets are located in the local .env.', project_id: mcp_projects:governance };

-- 3. Incidents
UPSERT mcp_incident:g3826w7hbr01xgdoreyd CONTENT { title: 'Connection string parsing error due to special characters in password', status: 'solved', programming_language: '', symptom: 'SurrealDB client fails to connect or throws \'Parse error\' when using generated passwords in connection strings.', status_detail: 'Implemented Global Rule (Priority 90) to enforce clean password generation.', project_id: mcp_projects:governance };
UPSERT mcp_incident:hmk7gvy1obc45pzn2xrw CONTENT { title: 'System Initialization Verification', status: 'solved', programming_language: 'Rust', symptom: 'User verification of database persistence stability.', status_detail: '', project_id: mcp_projects:governance };

COMMIT TRANSACTION;
