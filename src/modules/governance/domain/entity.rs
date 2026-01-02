#![allow(dead_code)]
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SdlcPhase {
    #[serde(rename = "planning")]
    Planning,
    #[serde(rename = "design")]
    Design,
    #[serde(rename = "implementation")]
    Implementation,
    #[serde(rename = "verification")]
    Verification,
    #[serde(rename = "maintenance")]
    Maintenance,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum RuleType {
    #[serde(rename = "global")]
    Global,
    #[serde(rename = "project")]
    Project,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernanceRule {
    pub id: String,
    pub rule_type: RuleType,
    pub project_id: Option<String>,
    pub category: String,
    pub content: String,
    pub priority: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
