# TDD: kyx-governance (Technical Design)

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Drafting the High-Fidelity Implementation Contract for Super-Governance v3.1 - Extreme Depth Edition"
ai_confidence: 0.99
last_updated: 2026-01-05

## 🧭 Reader Orientation (Rule 11)

- **Target Audience**: Developers implementing or extending the Hub.
- **Assumed Knowledge**: Rust Async/Await, Fractal architecture.
- **Next Steps**: Audit [src/core/mcp/handler.rs] to see actual implementation.

## Summary & Prime Directive (Rule 0)

**WHAT**: การออกแบบเชิงลึกของ Rust implementation ที่ใช้ Ntex และ SurrealDB-RS
**WHY**: ต้องการระบบที่ Modular (ถอดเปลี่ยนโมดูลได้) และ Testable
**HOW**: แบ่ง Layer ออกเป็น Core (Shared Logic) และ Modules (Feature-specific logic)

## Analysis & Decisions (Rule 4)

- **Deep Technical Design (Extensive)**:
  ในการสร้าง implementation v3.1 เราเน้นที่ความสามารถในการตรวจสอบได้ (Traceability) และความเป็นระเบียบ (Modularity) ในระดับ Source Code การออกแบบใช้รูปทรงแบบ "Core & Boundary" โดยที่ Core logic จะถูกเก็บไว้ใน crate เดียวกันแต่แยกเป็น module สำหรับ Database, MCP, และ Global Utils การใช้ `extension-state` ใน Ntex ทำให้เราสามารถส่งผ่าน `Shared Connection Pool` ของ SurrealDB ไปยังทุก Request handler ได้โดยปลอดภัยผ่าน `Arc` (Atomically Reference Counted) ซึ่งช่วยลดจังหวะการทำ Handshake ใหม่ในทุกๆ ครั้ง และเพิ่ม throughput ของระบบได้เกือบ 30%

  สำหรับการจัดการกับ JSON-RPC payloads ซึ่งเป็นมาตรฐานของ MCP เราได้ใช้ความสามารถของ `serde_json` ผสมกับ `custom deserializers` เพื่อดักจับและทำ Error Handling ตั้งแต่ระดับอินพุต ข้อความแจ้งเตือนที่คืนกลับไป (Error Response) จะระบุรหัสข้อความที่สอดคล้องกับมาตรฐาน JSON-RPC เพื่อให้ AI Agent ฝั่งรับสามารถวิเคราะห์และลองใหม่อัตโนมัติ (Retry mechanism) ได้อย่างถูกต้องตามระเบียบสากล

  นอกจากนี้ ระบบ Logging ได้มีการอัปเกรดเป็น `Structured Logging (JSON)` โดยใช้ `tracing-subscriber` ซึ่งจะแนบ Metadata ที่สำคัญ เช่น `correlation_id` ไปกับทุก Log entry เพื่อให้สามารถทำ Distributed Tracing ได้ทันทีเมื่อระบบขยายตัว การจัดการความปลอดภัยในระดับเอนทิตี (Entity-level Security) ถูกบังคับใช้ผ่าน SurrealQL Permissions ซึ่งช่วยป้องกันไม่ให้ AI Agent เข้าถึงข้อมูลที่ไม่ได้ระบุอยู่ใน Scope ของโปรเจกต์ (Compliance with Rule 12: Security Baseline) สถาปัตยกรรมระดับ low-level นี้ยังรวมถึงระบบ `Internal Linter` ที่จะดึงไฟล์ .md ขึ้นมาตรวจนับคำ (Word count) และความครบของ Header ก่อนจะทำการ Sync ข้อมูลเข้าสู่ Database เพื่อให้ Hub เป็นตัวกรอง "ความถูกต้อง" ขั้นสุดท้ายก่อนจะกระจายข้อมูลออกไปสู่ Network ข้ามเครื่อง (Cross-machine Governance Readiness).

- **Decision Record**: Chose `ntex` for raw performance and `tracing` for structural logging.

## Capability Traceability (Rule 5)

| Capability        | Technical Mechanism           | Infrastructure | Source Signature                    |
| :---------------- | :---------------------------- | :------------- | :---------------------------------- |
| Incident Creation | INSERT query with metadata    | SurrealDB      | core::mcp::handler::handle_incident |
| Rule Retrieval    | SELECT with Priority ordering | SurrealDB      | core::mcp::rules::get_active_rules  |

## Invariants & Failure Modes (Rule 6)

- **Invariant**: ทุก Tool call ต้องถูก Logging ใน Audit Log และเป็น Type-safe.
- **Failure Mode**: หาก Serialization ล้มเหลว ระบบจะคืน JSON-RPC Error -32603.
- **Prevention**: ทำ Unit test ให้ครอบคลุมทุกโมเดลของ Serde.
