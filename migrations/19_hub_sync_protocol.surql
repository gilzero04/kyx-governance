-- KYX Governance v3.1: Hub Synchronization Protocol (Rule 19)
-- Purpose: Eliminate "Silent Sync Failures" by enforcing UPSERT patterns.

BEGIN TRANSACTION;

-- 1. Codify Rule 19 (Global)
CREATE ai_rules:rule_19 CONTENT {
    name: "Rule 19: Hub Synchronization Protocol",
    priority: 15,
    content: "AI AGENTS must treat the Governance Hub as an IMMUTABLE log that requires explicit UPSERT patterns.
    
    1. THE UPDATE LIMITATION: The 'update-document' tool uses a 'WHERE' clause. If the record DOES NOT exist, it returns success but performs NO action.
    2. THE SYNC PROTOCOL: Before updating, AI must:
       a) Use 'upsert-document' (Atomic), OR
       b) Verify existence via 'list-documents' before using 'update-document'.
    3. DATA INTEGRITY: Any synchronization resulting in 'None' or '[]' for a new document is a CRITICAL FAILURE. Use 'sync-snapshot' as a fallback for bulk recovery.",
    project_id: mcp_projects:global,
    type: "global"
};

-- 2. Update Tool Metadata for 'update-document'
UPDATE mcp_tools:update_document SET 
    description = "Modifies an EXISTING SDLC document. WARNING: This tool will NOT create a new document if it doesn't exist. For new documents, use 'upsert-document'."
WHERE name = "update-document";

-- 3. Create the 'upsert-document' tool (Atomic Creation/Update)
UPSERT mcp_tools:upsert_document CONTENT {
    name: "upsert-document",
    title: "Upsert Document",
    description: "Atomically creates or updates an SDLC document. Recommended for all synchronization tasks to avoid silent failures.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string" },
            "phase": { "type": "string" },
            "name": { "type": "string" },
            "content": { "type": "string" },
            "title": { "type": "string" }
        },
        "required": ["project", "phase", "name", "content"]
    },
    active: true,
    execution_type: 'dynamic_sql',
    sql_template: "
        LET $p_id = (SELECT VALUE id FROM mcp_projects WHERE name = $project)[0];
        IF $p_id == NONE { RETURN 'Error: Project not found'; };
        
        -- Use a deterministic ID based on project and name if possible, or search for existing
        LET $existing = (SELECT VALUE id FROM mcp_documentation WHERE project_id = $p_id AND name = $name)[0];
        
        IF $existing != NONE {
            UPDATE $existing SET content = $content, updated_at = time::now() RETURN <string>id as id, title, 'updated' as action;
        } ELSE {
            CREATE mcp_documentation SET 
                project_id = $p_id, 
                sdlc_phase = $phase, 
                name = $name, 
                title = (IF $title IS NOT NONE THEN $title ELSE $name END), 
                content = $content, 
                updated_at = time::now() 
            RETURN <string>id as id, title, 'created' as action;
        };
    ",
    parameter_map: {
        "project": "project",
        "phase": "phase",
        "name": "name",
        "content": "content",
        "title": "title"
    },
    project_id: mcp_projects:governance
};

COMMIT TRANSACTION;
