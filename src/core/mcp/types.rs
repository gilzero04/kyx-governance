use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Resource {
    pub uri: String,
    pub name: String,
    pub description: Option<String>,
    #[serde(rename = "mimeType")]
    pub mime_type: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceContent {
    pub uri: String,
    #[serde(rename = "mimeType")]
    pub mime_type: Option<String>,
    pub text: Option<String>,
    pub blob: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Tool {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(skip_serializing)]
    #[allow(dead_code)]
    pub title: Option<String>,
    pub description: String,
    #[serde(alias = "input_schema")]
    pub input_schema: serde_json::Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(alias = "execution_type")]
    #[serde(skip_serializing)]
    pub execution_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(alias = "sql_template")]
    #[serde(skip_serializing)]
    pub sql_template: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(alias = "parameter_map")]
    #[serde(skip_serializing)]
    pub parameter_map: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(alias = "project_id")]
    #[serde(skip_serializing)]
    pub project_id: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CallToolResult {
    pub content: Vec<ToolContent>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub is_error: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ToolContent {
    #[serde(rename = "type")]
    pub content_type: String,
    pub text: Option<String>,
    pub image: Option<Value>,
}
