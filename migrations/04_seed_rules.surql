USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- P100: Standard Workflow
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 100,
    content: "Rule: Life-cycle Workflow.\n1. PRE-WORK: Identify project & check local snapshot in `knowledge_base/<project_name>.surql`.\n2. DURING-WORK: Log all changes locally in the snapshot file.\n3. POST-WORK:\n   - SYNC: Use `sync-snapshot` tool to upload the entire local `.surql` content in one go.\n   - VERIFY: Ensure `list-documents` reflects the latest changes.\n   - INCIDENT: Record any issues in `report-incident`.\n   - REPORT: Provide a summary of work done."
};

-- P98: Quality & Single Doc Policy
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 98,
    content: "Rule: Quality & Document Management.\n1. SINGLE DOCUMENT POLICY: Each project MUST have exactly ONE document per type (e.g., one PRD, one Architecture). Update these existing documents continuously instead of creating new ones.\n2. LINT & VERIFY: Never finish a task without running tests/lints/checks. Warnings must be addressed.\n3. TIMESTAMPS: All documents and incidents MUST include 'created_at' and 'updated_at' (managed by DB defaults)."
};

-- P97: SAFETY / BACKUP
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 97,
    content: "Rule: Safety & Backup.\n1. BACKUP FIRST: Before editing any critical file or data, ensure a backup exists or use version control to commit the current state.\n2. CLEANUP PROTOCOL: After verification, YOU MUST ASK the user for permission to delete backup files to keep the workspace clean."
};

-- P95: Incident Protocol
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 95,
    content: "Operational Rule: Incident Protocol. When encountering a problem/error: 1. SEARCH mcp_incident within the CURRENT project_id. 2. IF NOT FOUND locally, SEARCH GLOBALLY across all projects. 3. IF FOUND (Local or Global), apply the solution. 4. IF NOT FOUND, analyze root cause and RECORD a new entry in mcp_incident with: title, symptom, root_cause, solution, project_id, programming_language. 5. MANDATORY: Always set and report 'status' (solved/unsolved/investigating)."
};

-- P90: Security
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 90,
    content: 'Security Rule: Generated passwords and secrets MUST be at least 32 bytes long and use high entropy characters. IMPORTANT: To prevent connection string parsing errors, generated passwords MUST NOT contain the following characters: "@" (at), ":" (colon), "/" (slash), "?" (question), "#" (hash), "[" (left bracket), "]" (right bracket), "\\" (backslash), "\'" (single quote), """ (double quote), "$" (dollar), or whitespace.'
};

-- P89: Local Knowledge Sync
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 89,
    content: "Rule: Local Knowledge Sync (Snapshots).\n1. SOURCE OF TRUTH: The local file `knowledge_base/<project_name>.surql` is the working source of truth. Use `.surql` format.\n2. SNAPSHOT PROTOCOL: At start, Ensure the local file matches the DB. At end, ensure the DB matches the local file.\n3. REMOTE UPLOAD: When working via remote proxy, syncing MUST be done via the API/`curl` by sending the SQL commands from the local snapshot to the Hub's `tools/call` or dedicated sync endpoints."
};

-- P88: Navigation
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 88,
    content: "Rule: Navigation & Tool Usage.\n    1. WHERE TO LOOK:\n       - For Rules/Standards -> Use `search_governance` with query 'rule' or 'standard'.\n       - For System Architecture -> Read `kyx://<project>/design/architecture`.\n       - For API Details -> Read `kyx://<project>/implementation/api-reference`.\n       - For Past Issues -> Use `search_governance` to search Incidents.\n    2. WHAT TOOL TO USE:\n       - To Find Information -> `search_governance` (Primary Knowledge Tool).\n       - To Read Documents -> `resources/read` (Deep Dive).\n    3. PROTOCOL: Always 'Search' before asking."
};

-- P87: Environment
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 87,
    content: "Rule: Environmental Configuration. Critical project information, environment-specific variables, and connection strings for each project can be found and managed in the .env file within their respective directories."
};

-- P85: Documentation Standards
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 85,
    content: "Rule: Documentation Standards.\n1. CONTEXT: Every document MUST belong to a 'project_id'.\n2. SCHEMA DOCS: Must detail Field Names, Data Types, Constraints (Required/Default), and Relationships (PK/FK). No ambiguity allowed."
};

-- P82: Architecture Compliance
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 82,
    content: "Rule: Architecture Compliance.\n    1. STRUCTURE: Usage of standard templates (Rust/Svelte/etc) defined in `standard-architecture-templates` is MANDATORY.\n    2. REUSE: Always look for existing Shared Components (in `pkg`, `crate`, or `lib`) before coding from scratch.\n    3. DYNAMIC FIRST: If Logic is likely to change (e.g., pricing, rules, workflows), DO NOT hardcode it. Move it to the Database/Config."
};

-- P80: PDCA Workflow
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 80,
    content: "Rule: PDCA Workflow.\nEvery project MUST maintain a 'Master Workflow' document that tracks lifecycle artifacts:\n- PLAN: PRD, Architecture, Schema.\n- DO: Guides, Standards, **Operation/Usage Guide**.\n- CHECK: Test Plans, Verification Reports.\n- ACT: Deployment, Maintenance, Incidents.\nUpdate this document continuously; never delete it."
};

-- P52: Env Governance
CREATE ai_rules CONTENT {
    type: "project",
    project_id: mcp_projects:governance,
    priority: 52,
    content: "Rule: Governance Env. All governance secrets are located in the local .env."
};

-- P51: Global Variable Check
CREATE ai_rules CONTENT {
    type: "global",
    project_id: mcp_projects:global,
    priority: 51,
    content: "Rule: Global Variable Check. Verify that all global variables needed are defined in the environment."
};

-- P50: Kernel Rules
CREATE ai_rules CONTENT {
    type: "project",
    project_id: mcp_projects:kernel,
    priority: 50,
    content: "Kyx Kernel uses Rust/Ntex. Prefer functional patterns over imperative ones."
};

COMMIT TRANSACTION;
