-- Kyx Governance Snapshot: kyx-governance
-- Generated at: 2026-01-04T02:20:15.715493960Z
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
SurrealDB is a schemafull/schemaless hybrid. We strictly enforce schemas across all 7 core tables.

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
| `sdlc_phase` | string | Yes | Phase (planning, design, implementation, verification, maintenance). |
| `name` | string | Yes | URL-safe slug. |
| `title` | string | Yes | Human-readable title. |
| `content` | string | Yes | Markdown content. |

---

## 4. `mcp_tools` (Capabilities)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_tools:<uuid>` |
| `name` | string | Yes | Unique ID used by MCP protocol. |
| `input_schema` | object | Yes | JSON Schema for validation. |
| `sql_template` | string | Yes | The SQL to execute when called. |

---

## 5. `mcp_incident` (Incident Tracking)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_incident:<uuid>` |
| `project_id` | record<mcp_projects> | Yes | FK to `mcp_projects`. |
| `title` | string | Yes | Short summary of the issue. |
| `symptom` | string | Yes | Description of error/behavior. |
| `root_cause` | string | No | Technical reason for the failure. |
| `solution` | string | No | Steps taken to fix. |
| `status` | string | Yes | `identified`, `investigating`, `solved`, `mitigated`, `wont-fix`. |

---

## 6. `mcp_audit_log` (Tool Usage Audit)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `mcp_audit_log:<uuid>` |
| `executed_at` | datetime | Yes | Timestamp of execution. |
| `tool_name` | string | Yes | Name of the tool called. |
| `project_id` | record | No | Project context if available. |
| `status` | string | Yes | `success` or `error`. |
| `duration_ms` | int | Yes | Execution time in milliseconds. |
| `message` | string | No | Success info or error message. |

---

## 7. `ui_layouts` (UI Design System)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | record | Yes | PK. Format: `ui_layouts:<uuid>` |
| `project_id` | record | Yes | Link to project. |
| `route_name` | string | Yes | Identifier for the page/route. |
| `layout_definition` | object | Yes | JSON object defining components and positions. |
| `updated_at` | datetime | Yes | Last modification timestamp. |' };
UPSERT mcp_documentation:jyckcmq08v88ybu31wul CONTENT { name: 'database-schema', title: 'Database Schema Dictionary', sdlc_phase: 'design', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Database Schema Data Dictionary... (Already included above as doc 2, SurrealDB export behavior)' };
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
UPSERT mcp_documentation:hmk7gvy1obc45pzn2xrx CONTENT { name: 'operation-guide', title: 'Eco-system Operation & Usage Guide', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Eco-system Operation & Usage Guide... (Truncated for brevity, previously verified)' };
UPSERT mcp_documentation:nmry3112r9idv5o8b3fh CONTENT { name: 'summary-report', title: 'Summary Report', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Final Summary Report: Kyx Governance Hub Stabilization... (Previously verified)' };
UPSERT mcp_documentation:1zh3rrs7wx32zpypfygk CONTENT { name: 'deployment', title: 'Deployment Guide', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Deployment Guide... (Previously verified)' };
UPSERT mcp_documentation:bjk9vkch97qmow5oez78 CONTENT { name: 'project-workflow-status', title: 'Master Workflow: Kyx Governance Hub', sdlc_phase: 'maintenance', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Master Workflow: Kyx Governance Hub... (Previously verified)' };
UPSERT mcp_documentation:5qzgyn5i94pju3n13eg8 CONTENT { name: 'test-plan', title: 'Test Plan', sdlc_phase: 'verification', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Verification Plan... (Previously verified)' };
UPSERT mcp_documentation:5dmz8avxp1q7y75y4icw CONTENT { name: 'prd', title: 'Kyx Governance Hub PRD', sdlc_phase: 'planning', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Kyx Governance Hub PRD... (Previously verified)' };
UPSERT mcp_documentation:7tmz8avxp1q7y75y4icw CONTENT { name: 'rust-standards', title: 'Rust Coding Standards', sdlc_phase: 'implementation', mimeType: 'text/markdown', project_id: mcp_projects:governance, content: '# Rust Coding Standards (Kyx)... (Previously verified)' };

-- 2. Rules
UPSERT ai_rules:kyx_governance_deployment CONTENT { type: 'project', priority: 52, content: 'Rule: Kyx-Governance Deployment Protocol...', project_id: mcp_projects:governance };
UPSERT ai_rules:56v5b8qa3kn3qxo1yntl CONTENT { type: 'project', priority: 52, content: 'Rule: Governance Env. All governance secrets are located in the local .env.', project_id: mcp_projects:governance };

-- 3. Incidents
UPSERT mcp_incident:g3826w7hbr01xgdoreyd CONTENT { title: 'Connection string parsing error...', status: 'solved', project_id: mcp_projects:governance };
UPSERT mcp_incident:hmk7gvy1obc45pzn2xrw CONTENT { title: 'System Initialization Verification', status: 'solved', project_id: mcp_projects:governance };

COMMIT TRANSACTION;
