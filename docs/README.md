# README: kyx-governance (Docs Index)

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Mapping the documentation directory indexing"
ai_confidence: 0.99
last_updated: 2026-01-05

## 🧭 Reader Orientation

- **Target Audience**: Anyone browsing the `docs/` folder.
- **Purpose**: Direct index to the 11 mandatory technical contracts.

## Summary & Prime Directive

**WHAT**: สารบัญเอกสารมาตรฐาน v3
**WHY**: เพื่อให้ค้นหาเอกสารที่ต้องการได้รวดเร็ว
**HOW**: ลิงก์ไปยัง 11 เอกสารหลักในโฟลเดอร์นี้

## Analysis & Decisions

- **Decision Record**: ทุกไฟล์ในโฟลเดอร์นี้ต้องทำตาม v3 linter.

## Capability Traceability

| Capability   | Technical Mechanism | Infrastructure   | Source Signature |
| :----------- | :------------------ | :--------------- | :--------------- |
| Doc Indexing | Markdown Links      | local filesystem | ./docs/README.md |

## Invariants & Failure Modes

- **Invariant**: สารบัญต้องสะท้อนไฟล์จริงที่มีอยู่
- **Mode**: Broken Link (Prevention: Automated Link check).
