#![allow(dead_code)]
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};


#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DocumentationCategory {
    #[serde(rename = "database")]
    Database,
    #[serde(rename = "project")]
    Project,
    #[serde(rename = "standard")]
    Standard,
    #[serde(rename = "core")]
    Core,
    #[serde(rename = "api")]
    Api,
    #[serde(rename = "guide")]
    Guide,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Documentation {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    pub project_id: String,
    pub sdlc_phase: String,
    pub name: String,
    pub title: String,
    pub content: String,
    #[serde(rename = "mimeType")]
    pub mime_type: String,
    pub metadata: serde_json::Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
}
