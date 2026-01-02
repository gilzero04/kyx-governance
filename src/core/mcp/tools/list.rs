use crate::core::database::Database;
use crate::core::mcp::types::{CallToolResult, ToolContent};
use anyhow::Result;


pub struct ListProjectsTool {
    db: Database,
}

impl ListProjectsTool {
    pub fn new(db: Database) -> Self {
        Self { db }
    }

    pub async fn execute(&self) -> Result<CallToolResult> {
        let mut result = self.db.query("SELECT name, description, active FROM mcp_projects ORDER BY name ASC").await?;
        let projects: Vec<serde_json::Value> = result.take(0)?;
        
        // Format as JSON list for machine readability, but wrapped in text block
        let json_output = serde_json::to_string_pretty(&projects)?;
        
        Ok(CallToolResult {
            content: vec![ToolContent {
                content_type: "text".to_string(),
                text: Some(format!("Available Projects:\n```json\n{}\n```", json_output)),
                image: None,
            }],
            is_error: Some(false),
        })
    }
}

pub struct ListDocumentsTool {
    db: Database,
}

impl ListDocumentsTool {
    pub fn new(db: Database) -> Self {
        Self { db }
    }

    pub async fn execute(&self, project_filter: Option<&str>) -> Result<CallToolResult> {
        let query = if let Some(p) = project_filter {
            format!("SELECT title, name, sdlc_phase, project_id.name as project_name FROM mcp_documentation WHERE project_id.name = '{}' ORDER BY sdlc_phase, name", p)
        } else {
            "SELECT title, name, sdlc_phase, project_id.name as project_name FROM mcp_documentation ORDER BY project_name, sdlc_phase, name".to_string()
        };

        let mut result = self.db.query(&query).await?;
        let docs: Vec<serde_json::Value> = result.take(0)?;
        
        let json_output = serde_json::to_string_pretty(&docs)?;

        Ok(CallToolResult {
            content: vec![ToolContent {
                content_type: "text".to_string(),
                text: Some(format!("Documentation Index:\n```json\n{}\n```", json_output)),
                image: None,
            }],
            is_error: Some(false),
        })
    }
}

pub struct ListTechStackTool {
    db: Database,
}

impl ListTechStackTool {
    pub fn new(db: Database) -> Self {
        Self { db }
    }

    pub async fn execute(&self) -> Result<CallToolResult> {
        // Fetch the approved-tech-stack document directly
        let mut result = self.db.query("SELECT content FROM mcp_documentation WHERE name = 'approved-tech-stack'").await?;
        let doc: Option<serde_json::Value> = result.take(0)?;

        let content = doc.and_then(|d| d.get("content").and_then(|c| c.as_str()).map(|s| s.to_string()))
            .unwrap_or_else(|| "Global Tech Stack document not found.".to_string());

        Ok(CallToolResult {
            content: vec![ToolContent {
                content_type: "text".to_string(),
                text: Some(content),
                image: None,
            }],
            is_error: Some(false),
        })
    }
}
