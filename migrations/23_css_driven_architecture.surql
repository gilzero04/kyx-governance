USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- Rule: CSS-DRIVEN UI ARCHITECTURE
UPSERT ai_rules:platform_css_driven CONTENT {
    type: "project",
    project_id: mcp_projects:platform,
    priority: 95,
    content: "Rule: CSS-DRIVEN UI ARCHITECTURE.
All styling and UI configuration (colors, opacities, layer counts, dimensions, etc.) MUST be manageable exclusively via .css variables or classes. Svelte components (.svelte) MUST NOT have hardcoded stylistic props if those values need to be adjustable after project build. This ensures the environment remains themeable and modifiable without requiring source code recompilation."
};

COMMIT TRANSACTION;
