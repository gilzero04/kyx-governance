-- Kyx Governance Snapshot: kyx-governance
-- Generated at: 2026-01-02T11:33:35.672663720Z

BEGIN TRANSACTION;

-- 1. Documents
UPSERT mcp_documentation:7ivnpsk95s8wetdmoh80 CONTENT { content: '# System Architecture\n\n## Tech Stack\n- **Language**: Rust (Edition 2024)\n- **Web Framework**: Ntex (High performance async)\n- **Database**: SurrealDB (Multi-model)\n- **Runtime**: Docker (Debian Slim)\n\n## Components\n1. **HTTP Server**: Handles JSON-RPC 2.0 requests at `/mcp`.\n2. **Remote Proxy**: Secure interface for external agent connectivity.\n3. **Database Layer**: Direct connection to SurrealDB via `surrealdb` crate.\n4. **MCP Core**: Handles protocol messages (initialize, tools/list, resources/read).', mimeType: 'text/markdown', name: 'architecture', project_id: mcp_projects:governance, sdlc_phase: 'design', title: 'System Architecture (Verified by Test)' };
UPSERT mcp_documentation:0zqsezq2udukkq6m6ot7 CONTENT { content: '# Database Schema Data Dictionary\n\nThis document details the schema for all tables in the `kyx/governance` database as of version 1.1.\n\n## Overview\nSurrealDB is a schemafull/schemaless hybrid. We strictly enforce schemas.\n\n---\n\n## 1. `mcp_projects` (Projects)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `mcp_projects:<uuid>` |\n| `name` | string | Yes | Unique project identifier. |\n| `description` | string | No | Human-readable description. |\n| `active` | bool | Yes | Soft-delete flag. |\n\n---\n\n## 2. `ai_rules` (Governance Rules)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | PK. Format: `ai_rules:<uuid>` |\n| `type` | string | Yes | Scope: `global` or `project`. |\n| `priority` | int | Yes | Injection order. |\n| `content` | string | Yes | Rule text. |\n\n---\n\n## 3. `mcp_documentation` (Knowledge Base)\n| Field | Type | Required | Description |\n|-------|------|----------|-------------|\n| `id` | record | Yes | 
...
-- 2. Rules
UPSERT ai_rules:jeqc7elqai4z66nkhdbp CONTENT { content: 'Rule: Governance Env. All governance secrets are located in the local .env.', priority: 52, project_id: mcp_projects:governance, type: 'project' };

-- 3. Incidents
UPSERT mcp_incident:90riz3ngcbu8c1wt711p CONTENT { programming_language: '', project_id: mcp_projects:governance, status: 'solved', status_detail: 'Implemented Global Rule (Priority 90) to enforce clean password generation.', symptom: "SurrealDB client fails to connect or throws 'Parse error' when using generated passwords in connection strings.", title: 'Connection string parsing error due to special characters in password' };
UPSERT mcp_incident:lrbj8ubf4dmenn2szw8b CONTENT { programming_language: 'Rust', project_id: mcp_projects:governance, status: 'solved', status_detail: '', symptom: 'User verification of database persistence stability.', title: 'System Initialization Verification' };

COMMIT TRANSACTION;
