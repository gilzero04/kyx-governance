USE NS kyx;
USE DB governance;

-- -----------------------------------------------------------------------------
-- Kyx Governance Hub Schema (Consolidated)
-- -----------------------------------------------------------------------------


-- 1. Projects Pool
-- ----------------
DEFINE TABLE OVERWRITE mcp_projects SCHEMAFULL;
DEFINE FIELD name ON mcp_projects TYPE string;
DEFINE FIELD description ON mcp_projects TYPE string;
DEFINE FIELD active ON mcp_projects TYPE bool DEFAULT true;
DEFINE FIELD mcp_config ON mcp_projects TYPE object DEFAULT {};
DEFINE FIELD created_at ON mcp_projects TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON mcp_projects TYPE datetime DEFAULT time::now();

-- 2. Documentation & Knowledge Base
-- ----------------------------------
DEFINE TABLE OVERWRITE mcp_documentation SCHEMAFULL;
DEFINE FIELD project_id ON mcp_documentation TYPE record<mcp_projects>;
DEFINE FIELD sdlc_phase ON mcp_documentation TYPE string ASSERT $value INSIDE ['planning', 'design', 'implementation', 'verification', 'maintenance', 'none'];
DEFINE FIELD name ON mcp_documentation TYPE string;
DEFINE FIELD title ON mcp_documentation TYPE string;
DEFINE FIELD content ON mcp_documentation TYPE string;
DEFINE FIELD mimeType ON mcp_documentation TYPE string DEFAULT 'text/markdown';
DEFINE FIELD metadata ON mcp_documentation TYPE object DEFAULT {};
DEFINE FIELD created_at ON mcp_documentation TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON mcp_documentation TYPE datetime DEFAULT time::now();
DEFINE INDEX doc_name ON mcp_documentation FIELDS project_id, sdlc_phase, name UNIQUE;

-- 3. Tools Registry (Static & Dynamic)
-- ------------------------------------
DEFINE TABLE OVERWRITE mcp_tools SCHEMALESS;
DEFINE FIELD name ON mcp_tools TYPE string;
DEFINE FIELD description ON mcp_tools TYPE string;
DEFINE FIELD input_schema ON mcp_tools TYPE object;
DEFINE FIELD active ON mcp_tools TYPE bool DEFAULT true;
DEFINE FIELD project_id ON mcp_tools TYPE record<mcp_projects> VALUE $value OR none;
DEFINE FIELD execution_type ON TABLE mcp_tools TYPE string DEFAULT 'static' ASSERT $value INSIDE ['static', 'dynamic_sql', 'raw_sql'];
DEFINE FIELD sql_template ON TABLE mcp_tools TYPE string DEFAULT '';
DEFINE FIELD parameter_map ON TABLE mcp_tools TYPE object DEFAULT {};
DEFINE FIELD created_at ON mcp_tools TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON mcp_tools TYPE datetime DEFAULT time::now();
DEFINE INDEX tool_name ON mcp_tools FIELDS name UNIQUE;

-- 4. Governance Rules
-- -------------------
DEFINE TABLE OVERWRITE ai_rules SCHEMAFULL;
DEFINE FIELD type ON ai_rules TYPE string ASSERT $value INSIDE ['global', 'project'];
DEFINE FIELD project_id ON ai_rules TYPE record<mcp_projects> VALUE $value OR none;
DEFINE FIELD priority ON ai_rules TYPE int DEFAULT 0;
DEFINE FIELD content ON ai_rules TYPE string;
DEFINE FIELD created_at ON ai_rules TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ai_rules TYPE datetime DEFAULT time::now();

-- 5. Incident Tracking
-- --------------------
DEFINE TABLE OVERWRITE mcp_incident SCHEMAFULL;
DEFINE FIELD title ON mcp_incident TYPE string;
DEFINE FIELD symptom ON mcp_incident TYPE string;
DEFINE FIELD root_cause ON mcp_incident TYPE option<string>;
DEFINE FIELD solution ON mcp_incident TYPE option<string>;
DEFINE FIELD status ON mcp_incident TYPE string ASSERT $value INSIDE ['identified', 'investigating', 'solved', 'mitigated', 'wont-fix'];
DEFINE FIELD status_detail ON mcp_incident TYPE string DEFAULT '';
DEFINE FIELD project_id ON mcp_incident TYPE record<mcp_projects> VALUE $value OR none;
DEFINE FIELD programming_language ON mcp_incident TYPE string DEFAULT '';
DEFINE FIELD created_at ON mcp_incident TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON mcp_incident TYPE datetime DEFAULT time::now();
DEFINE INDEX incident_title_idx ON mcp_incident FIELDS title;

-- 6. UI Layouts (Metadata Driven UI)
-- ----------------------------------
DEFINE TABLE OVERWRITE ui_layouts SCHEMAFULL;
DEFINE FIELD project_id ON ui_layouts TYPE record<mcp_projects>;
DEFINE FIELD route_name ON ui_layouts TYPE string;
DEFINE FIELD layout_definition ON ui_layouts TYPE object; -- JSON definition for UI structure
DEFINE FIELD created_at ON ui_layouts TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON ui_layouts TYPE datetime DEFAULT time::now();
DEFINE INDEX ui_route_idx ON ui_layouts FIELDS project_id, route_name UNIQUE;

-- 7. Audit Logging
-- ----------------
DEFINE TABLE OVERWRITE mcp_audit_log SCHEMAFULL;
DEFINE FIELD tool_name ON mcp_audit_log TYPE string;
DEFINE FIELD project_id ON mcp_audit_log TYPE record<mcp_projects> VALUE $value OR none;
DEFINE FIELD arguments ON mcp_audit_log TYPE object DEFAULT {};
DEFINE FIELD status ON mcp_audit_log TYPE string ASSERT $value INSIDE ['success', 'error'];
DEFINE FIELD message ON mcp_audit_log TYPE string DEFAULT '';
DEFINE FIELD duration_ms ON mcp_audit_log TYPE int DEFAULT 0;
DEFINE FIELD executed_at ON mcp_audit_log TYPE datetime DEFAULT time::now();
