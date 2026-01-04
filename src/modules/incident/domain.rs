use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[allow(dead_code)]
pub struct Incident {
    pub title: String,
    pub symptom: String,
    pub root_cause: Option<String>,
    pub solution: Option<String>,
    pub status: String,
    pub project_name: Option<String>,
    pub programming_language: Option<String>,
}
