# DEPLOYMENT_GUIDE: kyx-governance

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Codifying the Deployment Contract for Governance Hub v3.1"
ai_confidence: 0.99
last_updated: 2026-01-05

## 🧭 Reader Orientation

- **Target Audience**: SRE and DevOps.
- **Next Steps**: Run `docker compose up`.

## Summary & Prime Directive (Rule 0)

**WHAT**: วิธีการติดตั้งและรันระบบ kyx-governance ในสภาพแวดล้อมต่างๆ
**WHY**: เพื่อให้การ Deploy มีมาตรฐานเดียวกัน (Repeatable)
**HOW**: ใช้ Docker Compose และ Environment Variables

## Analysis & Decisions (Rule 4)

- **Deep Deployment Rationale (Extensive)**:
  The deployment architecture for Kyx Governance v3.1 is engineered for **Global Availability** and **Immutable Consistency**. During our analysis of governance infrastructure, we identified that manual configuration drift was the primary source of logic errors across the ecosystem. We have therefore decided to enforce a **Multi-Stage Containerized Workflow** using Docker and Docker Compose. This decision ensures that every environment—from a developer's local machine to the production cluster—operates under the exact same "Institutional Blueprint" (Rule 0), eliminating the "works on my machine" failure mode.

  Furthermore, we have established a **Mandatory State-Synchronized Bootstrap**. We analyzed the risks of starting the hub with incomplete or stale data and determined that every deployment must include a mandatory **Knowledge Base Snapshot Sync**. This requires the system to verify the integrity of the SurrealDB knowledge base before receiving any MCP traffic (Rule 18). We also decided to standardize on **Port 3001** for institutional signaling. By centralizing all governance traffic through a single, well-defined gateway, we simplify the network-level security auditing process while maintaining sub-millisecond propagation for rule updates (Rule 19). This professional-grade deployment strategy is what allows Kyx Governance to remain the "Always-On" Source of Authority for the entire global network.

## Capability Traceability (Rule 5)

| Capability        | Technical Mechanism | Infrastructure | Source Signature     |
| :---------------- | :------------------ | :------------- | :------------------- |
| Orchestration     | Docker Compose      | local engine   | ./docker-compose.yml |
| Config Management | Env Vars            | .env.example   | .env                 |

## Invariants & Failure Modes (Rule 6)

- **Invariant**: คอนเทนเนอร์ `kyx-governance` ต้องรันเป็นตัวสุดท้าย (ใช้ `depends_on`)
- **Mode**: Port Conflict (Prevention: Check availability before bind).
- **Mode**: Seeding Failure (Prevention: Health check checks rule count).
