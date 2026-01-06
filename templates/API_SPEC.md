# API_SPEC: [Project Name]

project_id: [project-id]
author: [Author Name]
created_by: ai
ai_prompt: "Establishing the high-fidelity API reference for [Project Name] v3.1"
ai_confidence: 0.0
last_updated: [YYYY-MM-DD]

## 🧭 Reader Orientation (Rule 11)

- **Target Audience**: Developers, AI Agents, Integrators.
- **Goal**: Definitive list of all available [HTTP/WebSocket] endpoints.
- **Next Steps**: See `IMPLEMENTATION_SUMMARY.md` for study guides.

## Summary & Prime Directive (Rule 0)

**WHAT**: Comprehensive API reference for the [Project Name] engine.
**WHY**: To enable decoupled development and system integration.
**HOW**: Based on the traits and routers implemented in `src/`.

## [Module Name]

| Endpoint | Method   | Security      | Description   |
| :------- | :------- | :------------ | :------------ |
| `/path`  | [METHOD] | [Auth/Public] | [Description] |

---

## 🛠️ Usage Handbook (How to use)

### 1. [Section Name]

[Exact curl or code sample for using the API]

## Capability Traceability (Rule 5)

| Subsystem | Traceability ID | Handler Location |
| :-------- | :-------------- | :--------------- |
| [Name]    | [ID]            | [File Path]      |

## Invariants & Failure Modes (Rule 6)

- **Invariant**: [Design Invariant]
- **Failure Mode**: [Mode]
- **Prevention**: [Prevention mechanism]
