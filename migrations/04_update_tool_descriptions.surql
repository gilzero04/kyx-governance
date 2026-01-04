-- Migration: Update Tool Descriptions to Action-Oriented Format
-- This enables AI to understand WHEN to call each tool

UPDATE mcp_tool SET description = 'Use this tool to retrieve all active governance rules for a specific project or global rules. Call this when the user asks "What are the rules for...", before generating code for a project, when validating code compliance, or when the user asks about coding standards or best practices.' WHERE name = 'list-active-rules';

UPDATE mcp_tool SET description = 'Use this tool to search across ALL governance documents and rules using keywords. Call this when the user asks broad questions like "How should I..." or "What is the standard for..." or needs to find specific guidance across multiple documents.' WHERE name = 'search-governance';

UPDATE mcp_tool SET description = 'Use this tool for AI-powered context-aware search through governance standards and documentation. Call this for complex natural language questions like "How do we handle authentication in microservices?" or when keyword search returns too many/too few results.' WHERE name = 'search-semantic';

UPDATE mcp_tool SET description = 'Use this tool to retrieve the approved languages, frameworks, and tools for the tech stack. Call this before suggesting any library or technology to verify it is approved, or when the user asks "Can I use [technology]?" or "Is [framework] approved?"' WHERE name = 'list-tech-stack';

UPDATE mcp_tool SET description = 'Use this tool to retrieve the database schema dictionary for a project including tables, fields, and relationships. Call this before generating database queries, migrations, or when the user asks about data structure, "What tables exist?", or "Show me the schema".' WHERE name = 'list-database-schema';

UPDATE mcp_tool SET description = 'Use this tool to retrieve an index of all SDLC documentation for a project across all phases. Call this when the user asks "What documentation exists?", "Show me the guides for...", or needs to browse available docs.' WHERE name = 'list-documents';

UPDATE mcp_tool SET description = 'Use this tool to update the content of an existing SDLC document. Call this when the user explicitly asks to "update", "modify", "change", or "improve" a document.' WHERE name = 'update-document';

UPDATE mcp_tool SET description = 'Use this tool to record a new incident in the governance database. Call this when the user reports a bug, issue, or problem, when you detect a rule violation in code, or when the user asks to "log", "report", or "record" an incident.' WHERE name = 'report-incident';

UPDATE mcp_tool SET description = 'Use this tool to count incidents filtered by status. Call this when the user asks "How many incidents...", needs statistics on open/closed incidents, or asks "What is the incident status?"' WHERE name = 'count-incidents';

UPDATE mcp_tool SET description = 'Use this tool to retrieve a list of all active projects in the Kyx ecosystem. Call this when the user asks "What projects exist?", "Show all projects", or when you need to validate if a project name is correct.' WHERE name = 'list-projects';
