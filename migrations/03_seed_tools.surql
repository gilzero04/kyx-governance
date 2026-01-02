USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- Search Governance (Dynamic)
CREATE mcp_tool CONTENT {
    name: "search-governance",
    title: "Search Governance",
    description: "Search across all governance documents and rules.",
    input_schema: {
        "type": "object",
        "properties": {
            "query": { "type": "string" }
        },
        "required": ["query"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT title, project_id.name as project, (content OR symptom) as detail FROM mcp_documentation, mcp_incident WHERE (title ~ $query OR content ~ $query OR symptom ~ $query)",
    parameter_map: {
        "query": "query"
    },
    project_id: mcp_projects:governance
};

-- List Projects (Dynamic)
CREATE mcp_tool CONTENT {
    name: "list-projects",
    title: "List Projects",
    description: "Returns a list of all active projects in the Kyx ecosystem.",
    input_schema: {
        "type": "object",
        "properties": {},
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT name, description, active FROM mcp_projects ORDER BY name ASC",
    parameter_map: {},
    project_id: mcp_projects:governance
};

-- List Documents (Dynamic)
CREATE mcp_tool CONTENT {
    name: "list-documents",
    title: "List Documents",
    description: "Returns an index of all SDLC documentation.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string" }
        },
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT title, name, sdlc_phase, project_id.name as project_name FROM mcp_documentation WHERE ($project IS NONE OR project_id.name = $project) ORDER BY project_name, sdlc_phase, name",
    parameter_map: {
        "project": "project"
    },
    project_id: mcp_projects:governance
};

-- List Tech Stack (Dynamic)
CREATE mcp_tool CONTENT {
    name: "list-tech-stack",
    title: "List Tech Stack",
    description: "Returns the approved languages, frameworks, and tools.",
    input_schema: {
        "type": "object",
        "properties": {},
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT content FROM mcp_documentation WHERE name = 'approved-tech-stack'",
    parameter_map: {},
    project_id: mcp_projects:governance
};

-- List Active Rules (Dynamic)
CREATE mcp_tool CONTENT {
    name: "list-active-rules",
    title: "List Active Rules",
    description: "Returns the active governance rules for a specific project or global rules.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string", "description": "Optional project name to get specific rules for." }
        },
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT content, priority, type FROM ai_rules WHERE (type = 'global') OR (project_id.name = $project) ORDER BY priority DESC",
    parameter_map: {
        "project": "project"
    },
    project_id: mcp_projects:governance
};

-- Count Incidents (Dynamic)
CREATE mcp_tool CONTENT {
    name: "count-incidents",
    title: "Count Incidents",
    description: "Dynamically counts incidents based on status.",
    input_schema: {
        "type": "object",
        "properties": {
            "status": { "type": "string" }
        },
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT count() FROM mcp_incident WHERE ($status IS NONE OR status = $status) GROUP ALL",
    parameter_map: {
        "status": "status"
    },
    project_id: mcp_projects:governance
};

-- Report Incident (Dynamic)
CREATE mcp_tool CONTENT {
    name: "report-incident",
    title: "Report Incident",
    description: "Records a new incident directly into the governance database.",
    input_schema: {
        "type": "object",
        "properties": {
            "title": { "type": "string" },
            "symptom": { "type": "string" },
            "status": { "type": "string" },
            "project": { "type": "string" },
            "language": { "type": "string" }
        },
        "required": ["title", "project"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "CREATE mcp_incident CONTENT { title: $title, symptom: $symptom, status: $status, project_id: (SELECT id FROM mcp_projects WHERE name = $project)[0].id, programming_language: $language, created_at: time::now() } RETURN <string>id as id, <string>project_id as project_id, title, symptom, status, status_detail, programming_language, root_cause, solution, created_at",
    parameter_map: {
        "title": "title",
        "symptom": "symptom",
        "status": "status",
        "project": "project",
        "language": "language"
    },
    project_id: mcp_projects:governance
};

-- Update Incident (Dynamic)
CREATE mcp_tool CONTENT {
    name: "update-incident",
    title: "Update Incident",
    description: "Updates an existing incident with root cause, solution, and new status.",
    input_schema: {
        "type": "object",
        "properties": {
            "id": { "type": "string", "description": "The record ID of the incident (e.g., 'mcp_incident:uuid')" },
            "status": { "type": "string", "description": "New status: identified, investigating, solved, mitigated, wont-fix" },
            "root_cause": { "type": "string" },
            "solution": { "type": "string" }
        },
        "required": ["id"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "UPDATE type::thing($id) SET status = IF $status IS NOT NONE THEN $status ELSE status END, root_cause = IF $root_cause IS NOT NONE THEN $root_cause ELSE root_cause END, solution = IF $solution IS NOT NONE THEN $solution ELSE solution END RETURN <string>id as id, title, status, root_cause, solution",
    parameter_map: {
        "id": "id",
        "status": "status",
        "root_cause": "root_cause",
        "solution": "solution"
    },
    project_id: mcp_projects:governance
};

-- List Database Schema (Dynamic)
CREATE mcp_tool CONTENT {
    name: "list-database-schema",
    title: "List Database Schema",
    description: "Returns the database schema dictionary for global or project-specific data.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string", "description": "Optional project name. If omitted, returns global schema." }
        },
        "required": []
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "SELECT title, content, updated_at FROM mcp_documentation WHERE (name ~ 'schema') AND ($project IS NONE OR project_id.name = $project OR project_id.name = 'kyx-global')",
    parameter_map: {
        "project": "project"
    },
    project_id: mcp_projects:governance
};

-- Update Document (Dynamic)
CREATE mcp_tool CONTENT {
    name: "update-document",
    title: "Update Document",
    description: "Updates the content of an existing SDLC document. Best for single document updates.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string" },
            "phase": { "type": "string" },
            "name": { "type": "string" },
            "content": { "type": "string" }
        },
        "required": ["project", "phase", "name", "content"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "UPDATE mcp_documentation SET content = $content, updated_at = time::now() WHERE project_id.name = $project AND sdlc_phase = $phase AND name = $name RETURN <string>id as id, title, updated_at",
    parameter_map: {
        "project": "project",
        "phase": "phase",
        "name": "name",
        "content": "content"
    },
    project_id: mcp_projects:governance
};

-- Sync Snapshot (Raw SQL - Batch Update)
CREATE mcp_tool CONTENT {
    name: "sync-snapshot",
    title: "Sync Local Snapshot",
    description: "Accepts a batch of SQL commands (from your local .surql snapshot) to synchronize the Hub database with your local changes. Use this for bulk updates.",
    input_schema: {
        "type": "object",
        "properties": {
            "sql_commands": { "type": "string", "description": "The SQL commands (UPDATE/INSERT) from your local snapshot file." }
        },
        "required": ["sql_commands"]
    },
    enabled: true,
    execution_type: 'raw_sql',
    project_id: mcp_projects:governance
};

-- Export Snapshot (Raw SQL - Generate .surql script)
CREATE mcp_tool CONTENT {
    name: "export-snapshot",
    title: "Export Project Snapshot",
    description: "Returns a single SQL script (.surql) containing all documents, rules, and incidents for a project. Ready to be saved to your local knowledge_base/ folder.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string", "description": "The project name (e.g., 'kyx-governance')" }
        },
        "required": ["project"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "LET $p_name = $project; LET $p_rec = (SELECT VALUE id FROM mcp_projects WHERE name = $p_name)[0]; IF $p_rec == NONE { RETURN 'Error: Project not found'; }; LET $docs = SELECT * FROM mcp_documentation WHERE project_id = $p_rec; LET $rules = SELECT * FROM ai_rules WHERE project_id = $p_rec; LET $incs = SELECT * FROM mcp_incident WHERE project_id = $p_rec; LET $header = '-- Kyx Governance Snapshot: ' + $p_name + '\\n-- Generated at: ' + type::string(time::now()) + '\\n\\nBEGIN TRANSACTION;\\n\\n'; LET $doc_sql = '-- 1. Documents\\n' + array::join((SELECT VALUE 'UPSERT mcp_documentation:' + meta::id(id) + ' CONTENT ' + type::string({ project_id: project_id, sdlc_phase: sdlc_phase, name: name, title: title, content: content, mimeType: mimeType }) + ';\\n' FROM $docs), ''); LET $rule_sql = '\\n-- 2. Rules\\n' + array::join((SELECT VALUE 'UPSERT ai_rules:' + meta::id(id) + ' CONTENT ' + type::string({ project_id: project_id, type: type, priority: priority, content: content }) + ';\\n' FROM $rules), ''); LET $inc_sql = '\\n-- 3. Incidents\\n' + array::join((SELECT VALUE 'UPSERT mcp_incident:' + meta::id(id) + ' CONTENT ' + type::string({ project_id: project_id, programming_language: programming_language, title: title, symptom: symptom, status: status, status_detail: status_detail }) + ';\\n' FROM $incs), ''); LET $footer = '\\nCOMMIT TRANSACTION;\\n'; RETURN $header + $doc_sql + $rule_sql + $inc_sql + $footer;",
    parameter_map: {
        "project": "project"
    },
    project_id: mcp_projects:governance
};

-- Export Report (Markdown - Presentation Ready)
CREATE mcp_tool CONTENT {
    name: "export-report",
    title: "Generate Project Report",
    description: "Generates a beautiful, human-readable Markdown report (.md) of all documents, rules, and incidents for a project. Perfect for presentations.",
    input_schema: {
        "type": "object",
        "properties": {
            "project": { "type": "string", "description": "The project name (e.g., 'kyx-governance')" }
        },
        "required": ["project"]
    },
    enabled: true,
    execution_type: 'dynamic_sql',
    sql_template: "LET $p_name = $project; LET $p_rec = (SELECT VALUE id FROM mcp_projects WHERE name = $p_name)[0]; IF $p_rec == NONE { RETURN '# Error: Project not found'; }; LET $docs = SELECT * FROM mcp_documentation WHERE project_id = $p_rec; LET $rules = SELECT * FROM ai_rules WHERE project_id = $p_rec; LET $incs = SELECT * FROM mcp_incident WHERE project_id = $p_rec; LET $title = '# Project Governance Report: ' + $p_name + '\\n\\n'; LET $meta = '> Generated at: ' + type::string(time::now()) + '\\n\\n---\\n\\n'; LET $doc_section = '## 📄 Documentation\\n\\n' + array::join((SELECT VALUE '### ' + title + '\\n' + content + '\\n\\n' FROM $docs), ''); LET $rule_section = '## ⚖️ Governance Rules\\n\\n| Priority | Type | Content |\\n|----------|------|---------|\\n' + array::join((SELECT VALUE '| ' + type::string(priority) + ' | ' + type + ' | ' + content + ' |\\n' FROM $rules), ''); LET $inc_section = '\\n\\n## 🛡️ Incident Logs\\n\\n' + array::join((SELECT VALUE '#### ' + title + '\\n- **Status**: ' + status + '\\n- **Language**: ' + programming_language + '\\n- **Symptom**: ' + symptom + '\\n- **Resolution**: ' + (status_detail OR 'N/A') + '\\n\\n' FROM $incs), ''); RETURN $title + $meta + $doc_section + $rule_section + $inc_section;",
    parameter_map: {
        "project": "project"
    },
    project_id: mcp_projects:governance
};


COMMIT TRANSACTION;
