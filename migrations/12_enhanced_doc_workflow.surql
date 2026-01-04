-- ============================================================================
-- Migration: Enhanced Document Management Workflow Rule
-- Created: 2026-01-03
-- Description: Add comprehensive document management workflow with PRE/POST work requirements
-- ============================================================================

USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- Enhanced Document Management Rule (Priority 99 - Very High)
CREATE ai_rules CONTENT {
  type: "global",
  project_id: mcp_projects:global,
  priority: 99,
  content: "Rule: Enhanced Document Management Workflow.

## PRE-WORK (ก่อนเริ่มงาน - บังคับทำทุกครั้ง):
1. ระบุ project ที่จะทำงาน
2. ดึงเอกสารล่าสุด: `list-documents(project=\\\"<name>\\\")`
3. Export snapshot: `export-snapshot(project=\\\"<name>\\\")`
4. อ่านเอกสารที่เกี่ยวข้องตาม SDLC phase:
   - Planning → PRD
   - Design → Architecture, Schema
   - Implementation → Standards, Operation Guide
   - Verification → Test Plan
   - Maintenance → Deployment, Master Workflow

## DURING-WORK (ระหว่างทำงาน):
1. บันทึกการเปลี่ยนแปลงใน local snapshot file (.surql)
2. ใช้ `update-document()` สำหรับแก้ไขทีละเอกสาร
3. เจอปัญหา:
   - ค้นหาก่อน: `search-governance(query=\\\"<keyword>\\\")`
   - ถ้าไม่มี → `report-incident()`
   - ถ้าแก้ได้ → `update-incident(status=\\\"solved\\\")`

## POST-WORK (หลังทำงานเสร็จ - บังคับทำทุกครั้ง):
1. **SYNC**: `sync-snapshot(sql_commands=\\\"<paste .surql content>\\\")`
2. **VERIFY**: `list-documents(project=\\\"<name>\\\")` ตรวจสอบว่าอัปเดตแล้ว
3. **UPDATE MASTER WORKFLOW** (บังคับ):
   update-document(project, phase=maintenance, name=project-workflow-status)
   Work Log Entry ต้องมี:
   - วันที่และเวลา (YYYY-MM-DD HH:MM-HH:MM)
   - ผู้ทำงาน
   - งานที่ทำ
   - ปัญหาที่พบ
   - ผลลัพธ์
   - **เอกสารที่แก้ไข**
4. **REPORT**: `export-report(project=\\\"<name>\\\")`

## CRITICAL RULES:
- ❌ **ห้ามลบเอกสาร** - แก้ไข/เพิ่มเติมได้ แต่ห้ามลบ
- ✅ **Single Document Policy**: 1 ประเภท = 1 เอกสาร
- ✅ **Master Workflow บังคับอัปเดต**: ทุกครั้งที่ทำงานเสร็จ
- ✅ **ระบุวันที่เวลา**: ทุก work log entry
- ✅ **บันทึกเอกสารที่แก้**: ระบุว่าแก้อะไรและเปลี่ยนอะไร

## Required Documents per Project:
PLAN: PRD, Architecture, Schema
DO: Standards, Operation Guide
CHECK: Test Plan, Verification Report
ACT: Deployment Guide, Master Workflow (ห้ามลบ!), Incidents Log"
};

COMMIT TRANSACTION;
