-- KYX Governance Ruleset v3 — AI-Native Specification
-- PERSISTENT MIGRATION: 17_ultimate_ruleset.surql (v3 Upgrade)

-- FULL RESET FOR V3
DELETE ai_rules;

-- RULE 0: PRIME DIRECTIVE (HIGHEST PRIORITY)
UPSERT ai_rules:rule_0 CONTENT {
    type: 'global',
    priority: 200,
    project_id: mcp_projects:global,
    content: "RULE 0 — PRIME DIRECTIVE. ทุกงานต้องตอบได้: 1. WHAT (ทำอะไร) 2. WHY (ทำไมถึงทำแบบนี้) 3. HOW (ทำงานจริงยังไง) 4. WHERE (จะพังตรงไหน) 5. PREVENTION (จะกันไม่ให้พังซ้ำยังไง). หากตอบไม่ครบ = งานยังไม่เสร็จ."
};

-- RULE 1: MASTER WORKFLOW (MANDATORY)
UPSERT ai_rules:rule_1 CONTENT {
    type: 'global',
    priority: 190,
    project_id: mcp_projects:global,
    content: "RULE 1 — MASTER WORKFLOW. PRE-WORK: ต้อง Sync snapshot, อ่าน PROJECT_OVERVIEW/PRD/SAD และเช็ค Incidents เสมอ. DURING-WORK: เน้นบันทึก WHY, อัปเดตเอกสารเดิม (Single Doc Policy). POST-WORK: Sync back, ตรวจสอบ Invariants, อัปเกรด Workflow Log และ Commit/Push สาขาใหม่ด้วย Analytical Commit Message."
};

-- RULE 2: PROJECT NARRATIVE LAYER
UPSERT ai_rules:rule_2 CONTENT {
    type: 'global',
    priority: 180,
    project_id: mcp_projects:global,
    content: "RULE 2 — PROJECT NARRATIVE LAYER. ทุกโปรเจกต์ต้องมี PROJECT_OVERVIEW.md อธิบายภาพรวมความหมายและวิวัฒนาการ ห้ามใส่รายละเอียด Implementation ระดับต่ำ."
};

-- RULE 3: STANDARD DOCUMENT SET
UPSERT ai_rules:rule_3 CONTENT {
    type: 'global',
    priority: 170,
    project_id: mcp_projects:global,
    content: "RULE 3 — STANDARD DOCUMENT SET. ต้องมีและรักษาเอกสารมาตรฐาน 12 ฉบับ (Overview, PRD, SAD, TDD, API_SPEC, Schema, Summary, Test Plan, Deploy, Ops, Workflow Log, AI_CONTEXT). PROJECT_OVERVIEW ต้องแสดงโครงสร้างโฟลเดอร์ที่ถูกต้องตามจริง (Verified Structure) และ IMPLEMENTATION_SUMMARY ต้องทำหน้าที่เป็น 'Project Study Guide' ที่มีโค้ดตัวอย่างและเส้นทางศึกษาที่ชัดเจน."
};

-- RULE 4: MANDATORY ANALYSIS & DECISION RECORD
UPSERT ai_rules:rule_4 CONTENT {
    type: 'global',
    priority: 160,
    project_id: mcp_projects:global,
    content: "RULE 4 — MANDATORY ANALYSIS & DECISION RECORD. ต้องบันทึก Objective, Assumptions, Alternatives, Trade-offs, Risks และ 'ทำไมถึงเลือกดีไซน์นี้' (Decision Record) เสมอ."
};

-- RULE 5: CAPABILITY TRACEABILITY
UPSERT ai_rules:rule_5 CONTENT {
    type: 'global',
    priority: 150,
    project_id: mcp_projects:global,
    content: "RULE 5 — CAPABILITY TRACEABILITY (NON-NEGOTIABLE). ทุกความสามารถต้องมี Traceability: Capability → Mechanism → Persistence/Infra → Source Signature (file::symbol)."
};

-- RULE 6: INVARIANTS & FAILURE MODES
UPSERT ai_rules:rule_6 CONTENT {
    type: 'global',
    priority: 140,
    project_id: mcp_projects:global,
    content: "RULE 6 — INVARIANTS & FAILURE MODES. ต้องกำหนด Design Invariants (ห้ามพัง) และ Failure Modes (เช่น Redis down, DB lag, Network partition)."
};

-- RULE 7: INCIDENT AS KNOWLEDGE
UPSERT ai_rules:rule_7 CONTENT {
    type: 'global',
    priority: 130,
    project_id: mcp_projects:global,
    content: "RULE 7 — INCIDENT AS KNOWLEDGE. Incident คือการเรียนรู้ ต้องบันทึก Root cause, Broken invariant และ 'Preventive rule' ใหม่ทุกครั้ง."
};

-- RULE 8: AI CONTEXT CONTROL
UPSERT ai_rules:rule_8 CONTENT {
    type: 'global',
    priority: 120,
    project_id: mcp_projects:global,
    content: "RULE 8 — AI CONTEXT CONTROL. ทุกโปรเจกต์ต้องมี AI_CONTEXT.md กำหนด Invariants, Non-goals และวิธีคิดของระบบ AI ต้องโหลดบริบทนี้ก่อนทำงานทุกครั้ง."
};

-- RULE 9: ZERO HARDCODE POLICY
UPSERT ai_rules:rule_9 CONTENT {
    type: 'global',
    priority: 110,
    project_id: mcp_projects:global,
    content: "RULE 9 — ZERO HARDCODE POLICY. ทุกการตั้งค่าต้องเป็น Dynamic ผ่าน Metadata หรือ Env Variables เท่านั้น ห้าม Hardcode ใน Binary."
};

-- RULE 10: ZERO AMBIGUITY LANGUAGE
UPSERT ai_rules:rule_10 CONTENT {
    type: 'global',
    priority: 100,
    project_id: mcp_projects:global,
    content: "RULE 10 — ZERO AMBIGUITY LANGUAGE. ใช้ภาษาที่ชัดเจน (MUST, NON-NEGOTIABLE, ATOMIC) ห้ามใช้ภาษาคลุมเครือ (Should, Maybe, Usually)."
};

-- RULE 11: DOCUMENTATION AS CONTRACT
UPSERT ai_rules:rule_11 CONTENT {
    type: 'global',
    priority: 95,
    project_id: mcp_projects:global,
    content: "RULE 11 — DOCUMENTATION AS CONTRACT. เอกสารคือสัญญาที่ผูกพัน หากโค้ดเปลี่ยนต้องอัปเดตเอกสาร (หรือกลับกัน) ความไม่ตรงกันถือเป็นการละเมิดกฎ."
};

-- RULE 12: SECURITY BASELINE
UPSERT ai_rules:rule_12 CONTENT {
    type: 'global',
    priority: 90,
    project_id: mcp_projects:global,
    content: "RULE 12 — SECURITY BASELINE. รหัสผ่าน/ความลับ ต้องมีความยาวขั้นต่ำ 32 bytes และมีความซับซ้อนสูง (High Entropy)."
};

-- RULE 13: QUALITY & LINT GATE
UPSERT ai_rules:rule_13 CONTENT {
    type: 'global',
    priority: 85,
    project_id: mcp_projects:global,
    content: "RULE 13 — QUALITY & LINT GATE. รักษามาตรฐาน Zero Warning, Rust 2024 และห้ามใช้ .unwrap() ในโค้ด Production."
};

-- RULE 14: PDCA KNOWLEDGE LOOP
UPSERT ai_rules:rule_14 CONTENT {
    type: 'global',
    priority: 80,
    project_id: mcp_projects:global,
    content: "RULE 14 — PDCA KNOWLEDGE LOOP. ทุกงานต้องร้อยเรียงกันในวงจร Plan → Do → Check → Act (เชื่อมโยง Code, Docs, Incidents และ Rules)."
};

-- RULE 15: SNAPSHOT SYNCHRONIZATION
UPSERT ai_rules:rule_15 CONTENT {
    type: 'global',
    priority: 75,
    project_id: mcp_projects:global,
    content: "RULE 15 — SNAPSHOT SYNCHRONIZATION. ไฟล์ Snapshot ใน knowledge_base/ คือแหล่งอ้างอิงความจริงสูงสุด ต้อง Sync ก่อนเริ่มและหลังจบงานเสมอ."
};

-- RULE 16: SEARCH BEFORE THINKING
UPSERT ai_rules:rule_16 CONTENT {
    type: 'global',
    priority: 70,
    project_id: mcp_projects:global,
    content: "RULE 16 — SEARCH BEFORE THINKING. ค้นหากฎ, Incident และสถาปัตยกรรมที่มีอยู่ก่อนจะเสนอทางแก้ ห้ามแก้ปัญหาที่ถูกแก้ไปแล้ว."
};

-- RULE 17: GIT HYGIENE & DELIVERY
UPSERT ai_rules:rule_17 CONTENT {
    type: 'global',
    priority: 60,
    project_id: mcp_projects:global,
    content: "RULE 17 — GIT HYGIENE & DELIVERY. เมื่อจบงานต้องสร้างสาขาใหม่และ Commit ด้วย Analytical message ที่อธิบาย WHAT, WHY และการตัดสินใจที่เกี่ยวข้อง."
};
