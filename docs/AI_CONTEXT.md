# AI_CONTEXT: kyx-governance

project_id: kyx-governance
author: Antigravity
created_by: ai
ai_prompt: "Establishing the AI reasoning layer for Governance Hub v3.1 - Enhanced Traceability"
ai_confidence: 1.0
last_updated: 2026-01-05

## 🧭 Reader Orientation

- **Target Audience**: AI Agents (Coding & Logic).
- **Purpose**: Define how an AI thinks when working on this repository.

## Summary & Prime Directive (Rule 0)

**WHAT**: Context layer for AI Agents.
**WHY**: Prevent hallucinations and ensure alignment with KYX Governance Rules.
**HOW**: You are bound by the AI-Native Lifecycle (Rule 0-17).

## Analysis & Decisions (Rule 4)

- **Deep Operational Rationale (Extensive)**:
  The AI Context Layer for Kyx Governance v3.1 is the supreme **Reasoning Foundation** for the entire ecosystem. During our analysis of AI behavioral patterns, we identified the lack of an "Institutional Brake"—where an agent prioritizes task speed over rule compliance—as the primary driver of technical debt. We have therefore mandated a **Compliance-First Reasoning Model**. This decision requires every AI agent to prioritize Rule 0 (The Prime Directive) over any specific technical objective, ensuring that the project's integrity is never sacrificed for short-term gains.

  Furthermore, we have codified a strict **Zero-Visibility Source Protocol** (Rule 18). We analyzed the risks of "Blind Edits" in networked environments and decided that if the codebase is not directly visible, the Governance Hub must be treated as the **EXCLUSIVE** source of truth. No code suggestions are permitted without first validating the intent against the `SAD.md` and `TDD.md` assets retrieved via MCP. We also decided to enforce a mandatory **150-word Cognitive Traceability Metric** (Rule 20). By forcing the AI to "think out loud" with deep technical rationales, we transform the documentation into a governed safety gate. This professional-grade discipline is what ensures that the Kyx ecosystem remains deterministic, verifiable, and resilient to the complexities of large-scale AI-automated development.

## Capability Traceability (Rule 5)

| Capability        | Technical Mechanism | Infrastructure           | Source Signature |
| :---------------- | :------------------ | :----------------------- | :--------------- |
| Logic Control     | System Prompt       | core::ai::prompts        | AI_CONTEXT.md    |
| Context Injection | MCP Tooling         | list-active-rules        | core::mcp::rules |
| Compliance Gate   | Linter Validation   | scripts/validate-docs.sh | Rule 3           |

## Invariants & Failure Modes (Rule 6)

- **Invariant**: AI must always perform Pre-work (Rule 1) before writing code.
- **Mode**: Context Overload (Prevention: Use `search-semantic` instead of reading all files).
- **Mode**: Output Truncation (Prevention: Strictly follow Template word count and header rules).

### 📝 Prompt Canonical (v3.1)

"Objective: Execute task following KYX Governance v3.1.
Rules:

- Fill ALL sections in the template (Summary, Analysis, Capabilities, Failures).
- Maintain minimum 150 words for the 'Analysis & Decisions' section for high-impact tasks (PRD/SAD/TDD).
- Include mandatory AI Metadata (ai_prompt, ai_confidence) and created_by.
- Block yourself if ai_confidence < 0.7 and request Human Review.
- Never summarize 'Execution-Grade' documents; return them in full."

### 🔬 Few-Shot: Good vs Bad

#### ✅ GOOD (v3.1 Compliant)

```markdown
# PRD: Feature X

## Analysis & Decisions

- Decision Record: We chose X over Y because [deep technical rationale with 150+ words]
- Trade-offs: Latency vs Memory [detailed analysis]
```

#### ❌ BAD (Truncated)

```markdown
# PRD: Feature X

## Analysis

Implemented X. It works well.
```

## 🏁 Delivery Requirement (Rule 17)

- Changes MUST be on a new branch.
- Commit message MUST include the Rationale (WHY).
