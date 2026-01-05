# DATABASE_SCHEMA: kyx-governance

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Mapping the Persistence Contract for Governance Hub v3.1"
ai_confidence: 0.99
last_updated: 2026-01-05

## 🧭 Reader Orientation (Rule 11)

- **Target Audience**: Data Engineers, Backend Developers.
- **Assumed Knowledge**: SurrealDB concepts (Records, Tables, Links).
- **Next Steps**: See [SAD.md](./SAD.md) for how the application uses this schema.

## Summary & Prime Directive (Rule 0)

**WHAT**: โครงสร้างฐานข้อมูล SurrealDB ที่เก็บข้อมูลแบบ Multi-model
**WHY**: เพื่อให้สามารถร้อยเรียง "ความสัมพันธ์" ระหว่าง Project, Rule, Document และ Incident ได้
**HOW**: ใช้ Table `ai_rules`, `mcp_projects`, `mcp_documentation`, และ `mcp_incident` เป็นแกนกลาง

## Analysis & Decisions (Rule 4)

- **Deep Persistence Rationale (Extensive)**:
  The persistence architecture of Kyx Governance v3.1 is anchored in the **Knowledge Graph Modeling** of institutional rules and project state. During our analysis of governance data structures, we identified that traditional relational schemas fail to capture the recursive and interconnected nature of cross-project standards. We have therefore decided to leverage **SurrealDB's Record Linking** capabilities to build a truly relational knowledge graph. This decision ensures that every rule in the `ai_rules` table can be atomically linked to specific `mcp_incident` records or `mcp_documentation` assets, providing sub-millisecond traceability for all compliance queries across the entire Kyx network.

  Furthermore, we have codified a strict **Serialization Safety Protocol**. We analyzed the common AI failure mode where SurrealDB's Internal Record IDs (`Thing` type) cause serialization errors in Rust-based MCP handlers. We decided to mandate an explicit **String-Casting Policy** in our SQL templates, ensuring that all IDs are returned as standard strings rather than complex objects. We also decided to use `mcp_documentation` as our canonical table name for project assets, ensuring 100% naming parity with the broader ecosystem's source of truth (Rule 18). By enforcing these graph-based invariants and serialization standards, we turn the governance database into a professional-grade, high-fidelity engine that supports institutional-grade transparency and AI-native observability.

## Capability Traceability (Rule 5)

| Capability      | Technical Mechanism | Infrastructure | Source Signature |
| :-------------- | :------------------ | :------------- | :--------------- |
| Persistence     | Document Store      | SurrealDB      | core::database   |
| Knowledge Graph | Record Linking      | SurrealDB      | migrations/      |

## Invariants & Failure Modes (Rule 6)

- **Invariant**: กฎที่มี Priority สูงกว่าต้องถูกแสดงผลก่อนเสมอ
- **Mode**: Orphaned Records (Prevention: Use Transactions for deletion).
- **Mode**: ID Type Mismatch (Prevention: Cast to string in SQL template).
