-- KYX Governance v3.1: Super-Governance Layer
-- Enforces strict metadata and word-count contracts.

UPDATE ai_rules:rule_3 MERGE {
    name: "Rule 3: Single Document Set & Forced Compliance (v3.1)",
    priority: 170,
    content: "EVERY project must maintain EXACTLY 11 documents in /docs. 
    AI AGENTS MUST follow the /templates/ exactly.
    
    MANDATORY SECTIONS:
    1. 🧭 Reader Orientation
    2. Summary & Prime Directive (Rule 0)
    3. Analysis & Decisions (Rule 4) -> MIN 150 WORDS for PRD/SAD/TDD
    4. Capability Traceability (Rule 5)
    5. Invariants & Failure Modes (Rule 6)
    
    AI METADATA IS NON-NEGOTIABLE:
    - created_by: <human|ai>
    - ai_prompt: <full_context>
    - ai_confidence: <score>
    - MERGE BLOCKED if ai_confidence < 0.7",
    project_id: mcp_projects:global,
    type: "global",
    updated_at: time::now()
};

-- Update Thai translation if necessary (skipping for brevity in migration, but standard in v3)
