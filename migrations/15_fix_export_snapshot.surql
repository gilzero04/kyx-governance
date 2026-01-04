USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- Improved version with better syntax and error handling
UPDATE mcp_tools SET
    sql_template = "
        LET $p_name = $project;
        LET $p_rec = (SELECT VALUE id FROM mcp_projects WHERE name = $p_name)[0];
        IF $p_rec == NONE { RETURN '-- Error: Project not found'; };
        
        LET $docs_count = (SELECT count() FROM mcp_documentation WHERE project_id = $p_rec GROUP ALL)[0].count OR 0;
        
        LET $header = '-- Kyx Governance Snapshot: ' + $p_name + '\\n' +
                      '-- Generated at: ' + type::string(time::now()) + '\\n' +
                      '-- Documents found: ' + type::string($docs_count) + '\\n\\n' +
                      'USE NS kyx; USE DB governance;\\n\\n' +
                      'BEGIN TRANSACTION;\\n\\n';
        
        LET $docs = (SELECT * FROM mcp_documentation WHERE project_id = $p_rec ORDER BY sdlc_phase, name);
        LET $doc_sql = '-- 1. Documents\\n' + array::join((SELECT VALUE 
            'UPSERT ' + type::string(id) + ' CONTENT { ' + 
            'name: \\'' + name + '\\', ' +
            'title: \\'' + title + '\\', ' +
            'sdlc_phase: \\'' + sdlc_phase + '\\', ' +
            'mimeType: \\'' + mimeType + '\\', ' +
            'project_id: ' + type::string(project_id) + ', ' +
            'content: ' + type::string(content) + ' ' +
            '};\\n' FROM $docs), '');
            
        LET $rules = (SELECT * FROM ai_rules WHERE project_id = $p_rec ORDER BY priority DESC);
        LET $rule_sql = '\\n-- 2. Rules\\n' + array::join((SELECT VALUE 
            'UPSERT ' + type::string(id) + ' CONTENT { ' + 
            'type: \\'' + type + '\\', ' +
            'priority: ' + type::string(priority) + ', ' +
            'content: \\'' + string::replace(content, '\\'', '\\\\\\'') + '\\', ' +
            'project_id: ' + type::string(project_id) + ' ' +
            '};\\n' FROM $rules), '');
            
        LET $incs = (SELECT * FROM mcp_incident WHERE project_id = $p_rec);
        LET $inc_sql = '\\n-- 3. Incidents\\n' + array::join((SELECT VALUE 
            'UPSERT ' + type::string(id) + ' CONTENT { ' + 
            'title: \\'' + title + '\\', ' +
            'status: \\'' + status + '\\', ' +
            'programming_language: \\'' + programming_language + '\\', ' +
            'symptom: \\'' + string::replace(symptom, '\\'', '\\\\\\'') + '\\', ' +
            'status_detail: \\'' + string::replace(status_detail, '\\'', '\\\\\\'') + '\\', ' +
            'project_id: ' + type::string(project_id) + ' ' +
            '};\\n' FROM $incs), '');
        
        LET $footer = '\\nCOMMIT TRANSACTION;\\n';
        
        RETURN $header + $doc_sql + $rule_sql + $inc_sql + $footer;
    ",
    updated_at = time::now()
WHERE name = 'export-snapshot';

COMMIT TRANSACTION;
