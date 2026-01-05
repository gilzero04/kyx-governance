# OPERATION_GUIDE: kyx-governance (Manual)

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Creating the User & Agent Manual for Governance Hub v3.1"
ai_confidence: 0.99
last_updated: 2026-01-05

## 🧭 Reader Orientation (Rule 11)

- **Target Audience**: Users who want to operate the Governance Hub manually or via AI.
- **Assumed Knowledge**: Terminal usage, Docker basic.
- **Next Steps**: See [Deployment Guide](./DEPLOYMENT.md) for server setup.

## Summary & Prime Directive (Rule 0)

**WHAT**: Runbook for system operation.
**WHY**: Prevent downtime via standardized responses.
**HOW**: Human-in-the-loop and Agent-network protocols.

## Analysis & Decisions (Rule 4)

- **Deep Operational Rationale (Extensive)**:
  The operational philosophy of Kyx Governance v3.1 is defined by **Predictive Resilience** and **Human-Agent Collaboration**. During our analysis of real-time governance failures, we found that rigid automated systems often lacked the necessary nuance for "Emergency Rule Overrides." We have therefore decided to implement a **Human-in-the-Loop Override Protocol**. This decision allows senior stakeholders to provide manual interventions during critical incidents, ensuring that the system can adapt to unforeseen edge cases while maintaining a high-fidelity audit trail in the Governance Hub (Rule 14).

  Furthermore, we have codified a 100% mandatory **Canonical Prompt Strategy** for all AI agent operations. We analyzed the impact of "Instruction Fragmentation" and determined that every interaction with the hub must be anchored in a unified, Super-Governance v3.1 compliant context. We also decided to enforce a **Stateless MCP Connection Model**. By maintaining the entire system state within the SurrealDB knowledge graph rather than the server memory, we ensure that the Hub can be instantly restarted or scaled across multiple instances without losing the session context of active AI agents (Rule 18). This professional-grade operational design is what allows the Kyx ecosystem to remain stable under extreme load, providing both humans and agents with a reliable, institutional-grade "Source of Authority."

## Capability Traceability (Rule 5)

| Capability      | Technical Mechanism | Infrastructure | Source Signature              |
| :-------------- | :------------------ | :------------- | :---------------------------- |
| Restart         | Docker CLI          | local engine   | docker restart kyx-governance |
| Health Check    | HTTP GET            | Port 3001      | curl /health                  |
| Rule Management | SQL Migrations      | SurrealDB      | migrations/\*.surql           |

## 1. Introduction

คู่มือนี้ระบุวิธีการใช้งานและดูแลรักษาระบบ **Kyx Governance Hub** ทั้งในมุมมองของคน (Human) และเอเจนท์ (AI)

## 2. Manual Operations

### 2.1 สั่งงานผ่าน CLI

เราใช้ Docker เป็นหลักในการรันระบบ:

- **เริ่มระบบ**: `docker compose up -d`
- **ล้างข้อมูลและเริ่มใหม่**: `docker compose down -v && docker compose up -d --build`
- **ตรวจสอบสุขภาพ**: `curl http://localhost:3001/health`

## 3. AI Agent Operations (Network)

เอเจนท์ AI สามารถเชื่อมต่อผ่าน **Network** ด้วยโปรโตคอล MCP:

- **Endpoint**: `http://<hub-ip>:3001/mcp`
- **Pre-work**: AI ต้องเรียกใช้ `list-active-rules` เพื่อรับบริบทล่าสุดข้ามเครือข่าย

### 3.2 Zero-Visibility Operations (Network-Only)

ในกรณีที่เอเจนท์ทำงานผ่าน Network และ **มองไม่เห็น Source Code** ให้ถือปฏิบัติดังนี้:

1. **Source of Truth**: Governance Hub (via `list-documents`) คือความจริงสูงสุด (Absolute Truth).
2. **Exhaustive Retrieval**: เอเจนท์ต้องอ่าน `PRD.md`, `SAD.md`, และ `TDD.md` ทั้งหมดก่อนเริ่มงาน เพื่อจำลองโครงสร้างระบบในความจำ (Mental Schema).
3. **Doc-Driven Suggestion**: การเสนอเปลี่ยนแปลงต้องอ้างอิงตาม "สัญญาทางเทคนิค" ในเอกสารเหล่านี้ 100% หากเอกสารไม่ชัดเจน ห้ามเดา (Don't hallucinate code).
4. **Verification**: ใช้ Linter tool ใน Hub เพื่อตรวจสอบความถูกต้องของเอกสารใหม่ แม้จะไม่เห็นผลลัพธ์การรัน Code จริง.

## Invariants & Failure Modes (Rule 6)

- **Invariant**: MCP Connection must be available on port 3001.
- **Invariant**: Documentation in Hub must exceed 150 words analysis to be "Actionable" for Zero-Visibility agents.
- **Mode**: MCP Connection Refused (Prevention: Health check port monitoring).
- **Mode**: High Latency (Prevention: Use local snapshots if > 500ms).
- **Mode**: Context Blindness (Prevention: Mandatory read of 11 core docs before any code edit).
