-- KYX Governance v3.1: Remote Handbook (Zero-Visibility Guidelines)
-- Purpose: Provide a network-accessible guide for AI Agents and Remote Ops.

BEGIN TRANSACTION;

INSERT INTO mcp_documentation (project_id, sdlc_phase, name, title, content, mimeType) 
VALUES (mcp_projects:global, 'maintenance', 'remote-handbook', 'Handbook: Zero-Visibility Remote Operations (v3.1)', '
# 📖 Handbook: Zero-Visibility Remote Operations (v3.1)

คู่มือนี้กำหนดแนวทางปฏิบัติ (Clear Guidelines) สำหรับการสร้างและแก้ไขเอกสารเพื่อให้มีคุณภาพระดับ High-Fidelity แม้ไม่เห็นโค้ด

## 🛠️แนวทางที่ 1: การสร้างเอกสารใหม่ (Creation Protocol)

เมื่อต้องสร้างเอกสารชุดใหม่ (Bootstrap) ให้ทำตามลำดับความสำคัญนี้:

1.  **Phase 1: Skeleton Pull**: ดึงไฟล์จาก /templates/*.md มาเป็นโครงสร้างตั้งต้นเสมอ
2.  **Phase 2: Project Identification**: ค้นหา Tech Stack และ Objective ของโปรเจกต์ผ่าน PROJECT_OVERVIEW.md (ถ้ามี) หรือถามระบบ
3.  **Phase 3: Fidelity Injection**: บังคับเขียนส่วน ## Analysis & Decisions ให้ยาวอย่างน้อย 150 คำ โดยห้ามใช้คำกว้างๆ (เช่น "Good performance") แต่ให้ใช้คำเฉพาะทาง (เช่น "Linear scalability via Redis Hash-sets")
4.  **Phase 4: Atomic Sync**: ใช้ upsert-document (ถ้ามี) หรือ sync-snapshot เท่านั้น ห้ามใช้ update-document กับไฟล์ที่ยังไม่มีใน Hub

## 🎭แนวทางที่ 2: การทำเนื้อหาให้ต่างกัน (Variation Framework)

เอกสารมาตรฐาน 11 ฉบับต้องมี "จิตวิญญาณ" ของโปรเจกต์นั้นๆ ห้ามเป็นเพียงเครื่องผลิตคำ (Template Hallucination)

| Project Type      | Focus Areas (MUST INCLUDE)                       | Rationale Examples                                     |
| :---------------- | :----------------------------------------------- | :----------------------------------------------------- |
| **System/Rust**   | Memory Safety, Ownership, Threading, Type-Safety | "Using Arc<RwLock> to manage global tool state..."   |
| **Real-time/Go**  | Concurrency (Goroutines), Latency, Pub/Sub       | "Backpressure handling using buffered channels..."     |
| **Frontend/Svelte** | State Management, UX Polishing, Hydration        | "Optimizing First Contentful Paint using Svelte 5..."  |
| **Infra/Docker**  | Security Hardening, Multi-stage, Networking      | "Reducing image size via Distroless to minimize CVEs..." |

## ✅ Checklist สำหรับความสำเร็จ (Fidelity Monitor)
- [ ] เนื้อหา Rationale (PRD/SAD/TDD) เกิน 150 คำหรือไม่?
- [ ] มีการระบุ Tech Stack ที่ใช้จริงในโปรเจกต์หรือไม่? (ไม่ใช่แค่เทคโนโลยีทั่วไป)
- [ ] มี Source Signature (เช่น struct::fn) เพื่อให้ตามหาใน Code จริงได้หรือไม่?
- [ ] มีการระบุ Failure Modes ที่อาจเกิดขึ้นจริงกับระบบนี้หรือไม่?

---

> [!IMPORTANT]
> **Variation = Intelligence.** หากเอเจนท์ไม่สามารถระบุความต่างทางเทคนิคระหว่างโปรเจกต์ได้ ถือว่าการทำ Governance ล้มเหลว', 'text/markdown');

COMMIT TRANSACTION;
