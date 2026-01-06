-- ════════════════════════════════════════════════════════════════════════════
-- Migration: 22_unified_master_governance.surql
-- Purpose: Add 12 new governance rules for Unified Master Governance v1.0
-- Categories: Financial Safety, Realtime/WebSocket, State Management, Quality
-- ════════════════════════════════════════════════════════════════════════════

USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- ════════════════════════════════════════════════════════════════════════════
-- 💰 RULE 4 — TRANSACTION & FINANCIAL SAFETY (Priority: 197)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 197,
    content: "RULE 4 — TRANSACTION & FINANCIAL SAFETY (CRITICAL).

HEAVY TRANSACTION DEFINITION: Any operation involving money, balance, ledger, settlement, retry/rollback, or idempotency.

MANDATORY RULES:
1. SurrealDB MUST NOT be source of truth for money/financial data
2. Financial mutations MUST be ACID-compliant (PostgreSQL required)
3. Financial domain MUST be isolated behind a Ledger Interface
4. AI MUST NEVER mutate financial state directly

SurrealDB MAY store: payment_intent, payment_state, payment_result (as mirrors only)
PostgreSQL MUST store: balances, transactions, ledger entries, settlements"
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🗄️ RULE 5 — DATABASE RESPONSIBILITY SPLIT (Priority: 196)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 196,
    content: "RULE 5 — DATABASE RESPONSIBILITY SPLIT.

RELATIONAL DB (PostgreSQL):
- Source of Truth for: Users, Tenants, RBAC, Financial, Audit
- ACID transactions, regulatory compliance, financial safety

SURREALDB:
- Context, Relations, AI Reasoning, Knowledge Base
- Real-time data, graph queries, document storage

CRITICAL: SurrealDB MAY mirror results, but MUST NOT originate truth for critical business data."
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🔌 RULE 6 — WEBSOCKET SCOPE (Priority: 196)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 196,
    content: "RULE 6 — WEBSOCKET SCOPE.

WebSocket IS FOR:
- Realtime signaling
- Chat events
- Meeting control
- Presence updates

WebSocket is NOT FOR:
- Source of truth (use DB)
- Media transport (use WebRTC)
- Financial execution (use HTTPS + DB)

NEVER embed business logic directly in WebSocket handlers."
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🔌 RULE 7 — WEBSOCKET MODE & ROOM LAW (Priority: 198)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 198,
    content: "RULE 7 — WEBSOCKET MODE & ROOM LAW.

Every connection MUST declare:

MODE (exactly one):
- chat: text messaging
- meeting: voice/video session
- broadcast: one-to-many stream

ROOM TYPE (exactly one):
- PRIVATE: 1:1 direct
- GROUP: many:many
- BROADCAST: 1:many

Server logic MUST branch by MODE + ROOM TYPE.
Role mutation after handshake is FORBIDDEN."
};

-- ════════════════════════════════════════════════════════════════════════════
-- 💬 RULE 8 — LIVECHAT GUARANTEES (Priority: 197)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 197,
    content: "RULE 8 — LIVECHAT GUARANTEES.

MANDATORY FIELDS:
- Explicit message_id (UUID)
- Explicit room_id
- Explicit sender_id

DELIVERY GUARANTEES:
- Idempotent handling (same message_id = no duplicate)
- At-least-once delivery
- ACK required from receiver
- Ordering guarantee: per-room ONLY (not global)"
};

-- ════════════════════════════════════════════════════════════════════════════
-- 📹 RULE 9 — LIVEVIDEO & MEETING AUTHORITY (Priority: 196)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 196,
    content: "RULE 9 — LIVEVIDEO & MEETING AUTHORITY.

SEPARATION OF CONCERNS:
- WebSocket handles: signaling ONLY
- Media MUST use: WebRTC, LiveKit, or dedicated transport

MEETING ROLES:
- host: full control (mute, kick, end)
- participant: can speak/share
- observer: view-only

Authority MUST be validated on EVERY privileged action.
Role escalation requires explicit host approval."
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🟢 RULE 10 — HEARTBEAT & PRESENCE (Priority: 196)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 196,
    content: "RULE 10 — HEARTBEAT & PRESENCE.

PROTOCOL:
- Heartbeat required (TTL-based, e.g., every 30s)
- Missing heartbeat = mark offline
- NO infinite presence assumption

BEHAVIOR:
- Disconnect is NORMAL (not error)
- Presence update on connect/disconnect/heartbeat
- Store presence in Redis with TTL, not permanent storage"
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🔄 RULE 11 — RECONNECT & RESUME (Priority: 195)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 195,
    content: "RULE 11 — RECONNECT & RESUME.

System MUST support:
1. Reconnect: allow re-establishing dropped connection
2. Resume: continue from last known state
3. State resync: fetch missed data on reconnect
4. Missed message recovery: query history since last_seen_id

CRITICAL: Never assume persistent connection.
Design for intermittent connectivity (mobile networks, WiFi drops)."
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🏗️ RULE 12 — STATE LOCATION RULE (Priority: 194)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 194,
    content: "RULE 12 — STATE LOCATION RULE.

STATE HIERARCHY:
1. Business state MUST live in Database (PostgreSQL/SurrealDB)
2. Session state lives in Redis (with TTL)
3. In-memory state MUST be reconstructible from DB/Redis

INVARIANT: Node restart MUST NOT corrupt system state.
If in-memory state is lost, system MUST recover gracefully from persistent storage."
};

-- ════════════════════════════════════════════════════════════════════════════
-- ⚡ RULE 13 — RATE LIMIT & BACKPRESSURE (Priority: 194)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 194,
    content: "RULE 13 — RATE LIMIT & BACKPRESSURE.

MANDATORY LIMITS:
- Per-connection rate limit (e.g., 100 msg/min)
- Per-room rate limit
- Global rate limit per tenant

BACKPRESSURE HANDLING:
- Slow consumer protection (drop or queue with limit)
- Infinite buffer is FORBIDDEN
- Graceful degradation under load"
};

-- ════════════════════════════════════════════════════════════════════════════
-- 🛡️ RULE 16 — QUALITY & SECURITY (Priority: 194)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 194,
    content: "RULE 16 — QUALITY & SECURITY.

ZERO WARNING POLICY:
- All warnings must be addressed before merge
- Rust 2024 edition required for kyx-kernel
- No .unwrap() in production code (use .expect() with message or proper error handling)

SECURITY:
- Secrets MUST be ≥ 32 bytes
- No secrets in code or documentation
- All secrets via environment variables

RUST SPECIFIC:
- Use Result<T, E> for fallible operations
- Implement proper error types per module"
};

-- ════════════════════════════════════════════════════════════════════════════
-- 📦 RULE 18 — SINGLE SOURCE OF TRUTH (Priority: 190)
-- ════════════════════════════════════════════════════════════════════════════
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 190,
    content: "RULE 18 — SINGLE SOURCE OF TRUTH.

LOCAL TRUTH: knowledge_base/<project>.surql
RUNTIME TRUTH: Governance Hub Database

SYNC PROTOCOL:
1. PRE-WORK: Sync local from DB (export-snapshot)
2. DURING-WORK: Update local .surql file
3. POST-WORK: Sync local to DB (sync-snapshot)

CONFLICT RESOLUTION: Local file wins during sync (overwrite remote)."
};

COMMIT TRANSACTION;
