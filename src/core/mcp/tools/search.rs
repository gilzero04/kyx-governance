use crate::core::database::Database;
use crate::core::mcp::types::{CallToolResult, ToolContent};
use anyhow::Result;

pub struct SearchGovernanceTool {
    db: Database,
}

impl SearchGovernanceTool {
    pub fn new(db: Database) -> Self {
        Self { db }
    }

    pub async fn execute(&self, query: &str) -> Result<CallToolResult> {
        // 1. Search Documentation
        let mut doc_result = self.db.query("
            SELECT title, content, sdlc_phase, project_id.name as project_name 
            FROM mcp_documentation 
            WHERE content CONTAINS $query OR title CONTAINS $query
        ")
        .bind(("query", query.to_string()))
        .await?;

        let doc_hits: Vec<serde_json::Value> = doc_result.take(0)?;
        
        let mut text_output = format!("Found results for '{}':\n\n", query);
        
        if !doc_hits.is_empty() {
            text_output.push_str("## 📚 Documentation Hits\n");
            for hit in &doc_hits {
                let title = hit.get("title").and_then(|v| v.as_str()).unwrap_or("Untitled");
                let project = hit.get("project_name").and_then(|v| v.as_str()).unwrap_or("unknown");
                let phase = hit.get("sdlc_phase").and_then(|v| v.as_str()).unwrap_or("none");
                let content = hit.get("content").and_then(|v| v.as_str()).unwrap_or("");
                
                text_output.push_str(&format!("### {} (Project: {}, Phase: {})\n{}\n\n---\n\n", 
                    title, project, phase, content));
            }
        }

        // 2. Search Incidents
        let mut inc_result = self.db.query("
            SELECT title, symptom, solution, status, project_id.name as project_name 
            FROM mcp_incident 
            WHERE title CONTAINS $query OR symptom CONTAINS $query OR solution CONTAINS $query
        ")
        .bind(("query", query.to_string()))
        .await?;

        let inc_hits: Vec<serde_json::Value> = inc_result.take(0)?;

        if !inc_hits.is_empty() {
            text_output.push_str("## 🚨 Incident Hits (Knowledge Base)\n");
            for hit in &inc_hits {
                let title = hit.get("title").and_then(|v| v.as_str()).unwrap_or("Untitled Issue");
                let project = hit.get("project_name").and_then(|v| v.as_str()).unwrap_or("unknown");
                let status = hit.get("status").and_then(|v| v.as_str()).unwrap_or("unknown");
                let symptom = hit.get("symptom").and_then(|v| v.as_str()).unwrap_or("");
                let solution = hit.get("solution").and_then(|v| v.as_str()).unwrap_or("No solution provided");
                
                text_output.push_str(&format!("### [INCIDENT] {} (Status: {})\n**Project**: {}\n**Symptom**: {}\n**Solution**: {}\n\n---\n\n", 
                    title, status, project, symptom, solution));
            }
        }

        if doc_hits.is_empty() && inc_hits.is_empty() {
            text_output.push_str("No results found in Documentation or Incident logs.");
        }

        Ok(CallToolResult {
            content: vec![ToolContent {
                content_type: "text".to_string(),
                text: Some(text_output),
                image: None,
            }],
            is_error: Some(false),
        })
    }
}
