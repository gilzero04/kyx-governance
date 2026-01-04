use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernanceDocument {
    pub title: String,
    pub content: String,
    pub project_name: String,
    pub sdlc_phase: String,
    pub name: String,
    #[serde(alias = "mimeType")]
    pub mime_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[allow(dead_code)]
pub struct GovernanceRule {
    pub title: String,
    pub content: String,
    pub priority: i32,
    pub enforcement: String,
}
