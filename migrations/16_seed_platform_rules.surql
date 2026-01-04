USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- 1. Ensure Platform Project exists
UPSERT mcp_projects:platform CONTENT {
    name: "kyx-platform",
    description: "Unified Console and Front-door for the Kyx Ecosystem",
    active: true
};

-- 2. Add Auto-Fix / Zero Warning Rule
-- We use a specific ID to ensure it is unique and upsertable
UPSERT ai_rules:platform_auto_fix CONTENT {
    type: "project",
    project_id: mcp_projects:platform,
    priority: 99,
    content: "Rule: Automatic Command Execution (Zero Warning Compliance).
The AI agent is explicitly authorized to automatically run the following commands with `SafeToAutoRun: true` for the `kyx-platform` project:
- `bun run lint` (ESLint & Style checks)
- `bun run check` (Svelte type & logic checks)
- `bun run format` (Prettier formatting)
- `npx eslint . --fix` (Automatic ESLint correction)
- `svelte-kit sync` (SvelteKit project synchronization)
- `bun install` (Dependency synchronization when needed for linting)
This authorization is granted to maintain the 'Zero Warning Policy' efficiently without requiring manual user approval for each execution."
};

COMMIT TRANSACTION;
