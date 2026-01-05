# PROJECT_OVERVIEW: kyx-governance

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Establishing the source of authority overview v3.1"
ai_confidence: 0.99
last_updated: 2026-01-05

## 🧭 Reader Orientation

- **Target Audience**: Everyone (Human & Agent).
- **Next Steps**: See `PRD.md`.

## Summary & Prime Directive (Rule 0)

**WHAT**: kyx-governance คือ "สมองส่วนกลาง" ของ Kyx Ecosystem
**WHY**: ป้องกัน AI Context Drift และสร้าง Executable Rules
**HOW**: ทำงานในรูปแบบ MCP (Model Context Protocol) Server เพื่อเป็นช่องทางให้ AI Agent เข้าถึงฐานความรู้ใน SurrealDB ได้โดยตรง

## Analysis & Decisions (Rule 4)

- **Deep Governance Rationale (Extensive)**:
  The architectural foundation of Kyx Governance v3.1 is predicated on the principle of **Institutional Traceability** and **Automated Compliance**. During our analysis of AI-driven ecosystems, we identified "Context Fragmentation"—where different agents operate under conflicting rules—as the primary threat to system integrity. We have therefore decided to establish this project as the absolute **Single Source of Truth (SSoT)** for the entire Kyx network. This decision ensures that every rule, document, and incident is managed within a unified, high-fidelity hub, preventing the occurrence of logic drift between disparate project modules.

  Furthermore, we have standardized on the **SurrealDB Knowledge Graph** for our data layer. We analyzed the complexity of multi-project governance and concluded that traditional relational models are insufficient for mapping the recursive relationships between global standards and project-specific variations. By leveraging graph-based linking, we enable sub-millisecond retrieval of the "Active Compliance Context" for any given project. We also decided to enforce **Super-Governance v3.1** as a mandatory logic gate. This ensures that no document enters the system without a deep, 150-word technical rationale (Rule 20), transforming the governance hub from a passive data store into an active, self-correcting authority that guarantees the professional integrity of the global Kyx ecosystem.

## Capability Traceability (Rule 5)

| Capability      | Technical Mechanism  | Infrastructure             | Source Signature           |
| :-------------- | :------------------- | :------------------------- | :------------------------- |
| Governance Hub  | Truth Source         | project_id: kyx-governance | core::mcp::handler         |
| Rule Engine     | Standard Enforcement | core::mcp::rules           | core::mcp::rules::verify   |
| Semantic Search | Context Retrieval    | Qdrant                     | core::mcp::handler::search |

## Invariants & Failure Modes (Rule 6)

- **Invariant**: Rule 0 must always hold.
- **Mode**: AI Context Drift (Prevention: Ruleset v3.1).
- **Mode**: Database Down (Prevention: Use locally synced snapshots for fallback).
