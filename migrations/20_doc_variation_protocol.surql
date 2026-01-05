-- KYX Governance v3.1: Documentation Variation & Creation Protocol (Rule 20)
-- Purpose: Prevent "Template Hallucination" and force project-specific technical depth.

BEGIN TRANSACTION;

-- 1. Update Rule 3 to include Variation awareness
UPDATE ai_rules:rule_3 SET content = content + "
    
    VARIATION PRINCIPLE:
    - Templates are MINIMAL bases.
    - AI MUST adapt sections to project-specific stacks (e.g. Ntex/Rust for Governance, Go/Redis for Signal).
    - Failure to provide PROJECT-SPECIFIC rationale in 'Analysis & Decisions' is a violation."
WHERE name = "Rule 3: Single Document Set & Forced Compliance (v3.1)";

-- 2. Codify Rule 20 (Global)
CREATE ai_rules:rule_20 CONTENT {
    name: "Rule 20: Documentation Creation & Detail Protocol",
    priority: 12,
    content: "
    CREATION PROTOCOL:
    1. Skeleton: Use /templates/*.md as base.
    2. Context: Identification of tech stack (e.g. Go/Redis vs Rust/SurrealDB) is MANDATORY.
    3. Fidelity: 'Analysis & Decisions' MUST be >150 words of deep technical rationale.
    4. Sync: Use 'upsert-document' for atomicity.
    
    VARIATION CHECKLIST:
    - Tech stack specific mechanisms (e.g. Goroutines, Ownership).
    - Failure modes specific to infrastructure (e.g. Redis backpressure).
    - Source signatures linking to specific file::symbols.",
    project_id: mcp_projects:global,
    type: "global"
};

COMMIT TRANSACTION;
