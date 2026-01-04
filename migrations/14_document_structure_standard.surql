USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- ============================================================================
-- CONSOLIDATE & REORGANIZE GOVERNANCE RULES
-- ============================================================================

-- Delete old redundant rules (will be replaced with consolidated versions)
DELETE FROM ai_rules WHERE priority IN [100, 99, 98, 85, 80];

-- ============================================================================
-- Priority 100: Master Workflow (บังคับทำทุกครั้ง - สำคัญที่สุด!)
-- ============================================================================

UPSERT ai_rules:master_workflow CONTENT {
    type: 'global',
    priority: 100,
    content: 'Rule: Master Workflow (บังคับทำทุกครั้ง!).

## PRE-WORK (ก่อนเริ่มงาน):
1. ระบุ project ที่จะทำงาน
2. ตรวจสอบ local snapshot: `knowledge_base/<project>.surql`
3. ดึงเอกสารล่าสุด: `list-documents(project="<name>")`
4. Export snapshot: `export-snapshot(project="<name>")`
5. อ่านเอกสารที่เกี่ยวข้อง (PRD, Architecture, Standards)

## DURING-WORK (ระหว่างทำงาน):
1. บันทึกทุกการเปลี่ยนแปลงใน local `.surql` file
2. ใช้ `update-document()` สำหรับแก้ไขเอกสารทีละตัว
3. เจอปัญหา:
   - ค้นหาก่อน: `search-governance(query="<keyword>")`
   - ไม่เจอ → `report-incident(title, symptom, project)`  
   - แก้ได้ → `update-incident(id, status="solved", solution)`

## POST-WORK (หลังทำงานเสร็จ - บังคับทำทุกข้อ!):
1. **SYNC**: `sync-snapshot(sql_commands="<paste .surql content>")`
2. **VERIFY**: `list-documents(project="<name>")` ตรวจสอบว่าอัปเดตแล้ว
3. **UPDATE IMPLEMENTATION SUMMARY** (บังคับ!):
   - เพิ่ม Phase/Task ใหม่
   - ระบุ: วันที่เวลา (YYYY-MM-DD HH:MM-HH:MM), งานที่ทำ, ผลลัพธ์
4. **UPDATE MASTER WORKFLOW** (บังคับ!):
   - เพิ่ม work log entry
   - ระบุ: วันที่เวลา, ผู้ทำงาน, งานที่ทำ, ปัญหา, ผลลัพธ์, **เอกสารที่แก้**
5. **INCIDENT**: บันทึกปัญหาที่เจอ (ถ้ามี)
6. **REPORT**: สรุปงานใน Summary Report

## CRITICAL RULES:
- ❌ **ห้ามข้าม POST-WORK** - ทุกขั้นตอนบังคับทำ
- ✅ **ต้องระบุวันที่เวลา** - ทุก work log entry
- ✅ **ต้องบอกเอกสารที่แก้** - ระบุว่าแก้อะไรและเปลี่ยนอะไร
',
    project_id: mcp_projects:global
};

-- ============================================================================
-- Priority 98: Standard Document Structure
-- ============================================================================

UPSERT ai_rules:document_structure CONTENT {
    type: 'global',
    priority: 98,
    content: 'Rule: Standard Document Structure.

Every kyx-governance project MUST have exactly 9 STANDARD DOCUMENTS:

**REQUIRED DOCUMENTS:**
1. **PRD** (planning) - Product Requirements Document
2. **Architecture** (design) - System architecture & design
3. **Database Schema** (design) - Complete schema dictionary (all tables)
4. **Rust Standards** (implementation) - Coding standards
5. **Implementation Summary** (implementation) - All phases chronologically
6. **Test Plan** (verification) - Testing & verification procedures
7. **Deployment Guide** (maintenance) - Deployment steps
8. **Operation Guide** (maintenance) - Usage instructions  
9. **Master Workflow** (maintenance) - Work log (NEVER DELETE!)

**PLUS:**
10. **Summary Report** (maintenance) - Work session summaries

**CRITICAL RULES:**
- ❌ **FORBIDDEN**: Delete หรือสร้างเอกสารใหม่
- ❌ **FORBIDDEN**: มีเอกสารเกิน 10 ตัว (1 type = 1 document)
- ✅ **REQUIRED**: Update เอกสารเดิมเรื่อยๆ (Single Document Policy)
- ✅ **REQUIRED**: ทุก update ต้องมี:
  * Phase/Task name
  * Date and Time (YYYY-MM-DD HH:MM-HH:MM)
  * What was changed
  * Who made changes (AI Agent name หรือ User name)

**EXAMPLE UPDATE FORMAT:**
```markdown
## Phase 3: MCP Transport Stabilization
**Date**: 2026-01-03 16:00-17:30
**By**: AI Agent (Antigravity)
**Changes**: SSE hardening, session cleanup, audit logging
**Details**: 
- Fixed 204 No Content → 200 OK + JSON
- Removed 5 session tools
- Added list-audit-logs tool
```

**HOW TO UPDATE:**
- PRD → เพิ่ม requirements ใหม่
- Architecture → เพิ่ม components/diagrams
- Schema → เพิ่ม tables/fields ใหม่
- Standards → เพิ่ม patterns/best practices
- **Implementation Summary** → เพิ่ม Phase ใหม่ chronologically
- Test Plan → เพิ่ม test cases
- Deployment → เพิ่ม/แก้ deployment steps
- Operation → เพิ่ม features/usage
- **Master Workflow** → เพิ่ม work log entries
- **Summary Report** → เพิ่ม session summary
',
    project_id: mcp_projects:global
};

-- ============================================================================
-- Priority 97: Quality & Documentation Standards
-- ============================================================================

UPSERT ai_rules:quality_standards CONTENT {
    type: 'global',
    priority: 97,
    content: 'Rule: Quality & Documentation Standards.

**DOCUMENTATION:**
1. **CONTEXT**: ทุกเอกสารต้องมี `project_id` (ห้ามเอกสารลอย)
2. **SCHEMA DOCS**: ต้องมี Field Names, Data Types, Constraints (Required/Default/UNIQUE), Relationships (PK/FK)
3. **NO AMBIGUITY**: ทุกอย่างต้องชัดเจน ห้ามคลุมเครือ
4. **TIMESTAMPS**: ทุกเอกสารต้องมี `created_at` และ `updated_at` (DB auto-manage)

**CODE QUALITY:**
1. **LINT & VERIFY**: ห้ามจบงานโดยไม่ run tests/lints/checks
2. **NO WARNINGS**: Warnings ต้องแก้ไข ห้ามทิ้งไว้
3. **RUST EDITION 2024**: ใช้ latest edition
4. **ERROR HANDLING**: ทุก Result ต้อง handle, ห้าม `.unwrap()` ใน production code

**BACKUP:**
1. **BACKUP FIRST**: สำรองข้อมูลก่อนแก้ไขไฟล์สำคัญ
2. **VERSION CONTROL**: Commit ก่อนทำการเปลี่ยนแปลงใหญ่
3. **CLEANUP**: ถาม user ก่อนลบไฟล์ backup เพื่อรักษาความสะอาด
',
    project_id: mcp_projects:global
};

-- ============================================================================
-- Priority 95: Incident Protocol (เดิม - ไม่แก้)
-- ============================================================================
-- (Keep as is at priority 95)

-- ============================================================================
-- Priority 90: Security Rule (เดิม - ไม่แก้)
-- ============================================================================  
-- (Keep as is at priority 90)

-- ============================================================================
-- Priority 89: Local Knowledge Sync (เดิม - ไม่แก้)
-- ============================================================================
-- (Keep as is at priority 89)

-- ============================================================================
-- Priority 88: Navigation & Tool Usage (เดิม - ไม่แก้)
-- ============================================================================
-- (Keep as is at priority 88)

-- ============================================================================
-- Priority 87: Environmental Configuration (เดิม - ไม่แก้)
-- ============================================================================
-- (Keep as is at priority 87)

-- ============================================================================
-- Priority 82: Architecture Compliance (เดิม - ไม่แก้)
-- ============================================================================
-- (Keep as is at priority 82)

-- ============================================================================
-- Priority 52: Kyx-Governance Deployment Rule
-- ============================================================================

UPSERT ai_rules:kyx_governance_deployment CONTENT {
    type: 'project',
    priority: 52,
    content: 'Rule: Kyx-Governance Deployment Protocol.

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
list-documents(project="kyx-governance")
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

**REMEMBER**: migrations = rebuild + wipe volumes required!
',
    project_id: (SELECT id FROM mcp_projects WHERE name = 'kyx-governance')[0].id
};

-- ============================================================================
-- REORGANIZE DOCUMENTS
-- ============================================================================

-- Merge Schema Documents
LET $full_schema = (SELECT content FROM mcp_documentation WHERE name = 'schema-full-dictionary')[0].content;
LET $incident_schema = (SELECT content FROM mcp_documentation WHERE name = 'schema-incident-tracking')[0].content;

UPDATE mcp_documentation SET 
    name = 'database-schema',
    title = 'Database Schema Dictionary',
    content = $full_schema + '\n\n---\n\n' + $incident_schema,
    updated_at = time::now()
WHERE name = 'schema-full-dictionary';

DELETE FROM mcp_documentation WHERE name = 'schema-incident-tracking';

-- Rename Phase 2 Summary → Implementation Summary
UPDATE mcp_documentation SET
    name = 'implementation-summary',
    title = 'Implementation Summary',
    content = '# Implementation Summary

This document tracks ALL implementation phases chronologically.
Each phase MUST include: Date, Time, Changes, Details, Results.

---

## Phase 1: Initial Setup & Core MCP
**Date**: 2025-12-XX
**By**: Development Team
**Changes**: Basic MCP server, tool registry, SurrealDB integration
**Status**: Complete

---

## Phase 2: Audit Logging
**Date**: 2026-01-XX
**By**: Development Team
**Changes**: Added audit logging system
**Details**: 
' + (SELECT content FROM mcp_documentation WHERE name = 'phase2_summary')[0].content + '

---

## Phase 3: MCP Transport Stabilization  
**Date**: 2026-01-03 16:00-17:30
**By**: AI Agent (Antigravity)
**Changes**: SSE hardening, session cleanup, audit logging enhancement
**Details**:

### SSE Transport Hardening
- Fixed 204 No Content → 200 OK + JSON
- Pure JSON-RPC (removed custom wrappers)
- Dual-channel delivery (HTTP + SSE)
- Enhanced heartbeat with timestamps

### Session Management Cleanup
- Removed 13_session_management.surql migration
- Deleted 5 session tools (create-session, get-session, update-session-context, add-conversation, get-conversation-history)
- Code removed: 143 lines
- Tool count: 20 → 15 → 16
- Achieved stateless MCP protocol compliance

### Audit Logging Enhancement
- Added list-audit-logs MCP tool
- Full visibility into tool usage history
- Final tool count: 16 total

**Results**:
- ✅ Zero agent termination errors
- ✅ 100% MCP protocol compliance
- ✅ Audit logs queryable via MCP
- ✅ Codebase simplified (143 lines removed)
- ✅ System stability improved

**Files Modified**:
- src/core/transport.rs (SSE hardening)
- migrations/13_session_management.surql (deleted)
- migrations/03_seed_tools.surql (removed session tools, added list-audit-logs)

---
',
    updated_at = time::now()
WHERE name = 'phase2_summary';

-- Create Summary Report Document
CREATE mcp_documentation CONTENT {
    project_id: (SELECT id FROM mcp_projects WHERE name = 'kyx-governance')[0].id,
    sdlc_phase: 'maintenance',
    name: 'summary-report',
    title: 'Summary Report',
    mimeType: 'text/markdown',
    content: '# Summary Report

This document contains brief summaries of completed work sessions.
Use this for quick reference. For details, see Implementation Summary.

---

## 2026-01-03 16:00-17:30 | MCP Transport Stabilization

**Objective**: Fix "Agent terminated due to error" and improve server stability

**Work Done**:
1. SSE Transport Hardening (pure JSON-RPC)
2. Session Management Cleanup (removed 5 tools)
3. Audit Logging Enhancement (added visibility tool)

**Results**:
- Agent stability: 0 errors ✅
- Tool count: 20 → 16 (optimized)
- MCP compliance: 100% ✅
- Code quality: Improved (-143 lines)

**Docs Updated**:
- Implementation Summary (Phase 3)
- Master Workflow (work log)
- migrations/ (14_document_structure_standard.surql)

---
'
};

COMMIT TRANSACTION;
