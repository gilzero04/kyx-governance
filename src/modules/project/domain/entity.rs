#![allow(dead_code)]
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use serde_json::Value;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectStack {
    pub languages: Vec<String>,
    pub framework: String,
    pub runtime: String,
    pub package_manager: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Project {
    pub id: String,
    pub name: String,
    pub description: String,
    pub stack: ProjectStack,
    pub configs: Value,             // Dynamic JSON for multi-project flexibility
    pub applied_standards: Vec<String>,
    pub mcp_hubs: Vec<String>,
    pub custom_rules: String,
    pub repo_url: Option<String>,
    pub docs_url: Option<String>,
    pub team: Vec<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
