use crate::core::database::Database;
use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Rule {
    pub content: String,
    pub priority: i32,
    pub r#type: String,
}

pub struct RuleManager {
    db: Database,
}

impl RuleManager {
    pub fn new(db: Database) -> Self {
        Self { db }
    }

    pub async fn get_combined_rules(&self, project_name: Option<&str>) -> Result<String> {
        let mut result = if let Some(pname) = project_name {
            self.db.query("
                SELECT content, priority, type FROM ai_rules 
                WHERE type = 'global' OR project_id.name = $project
                ORDER BY priority DESC
            ")
            .bind(("project", pname.to_string()))
            .await?
        } else {
            self.db.query("
                SELECT content, priority, type FROM ai_rules 
                WHERE type = 'global'
                ORDER BY priority DESC
            ")
            .await?
        };
        
        let rules: Vec<Rule> = result.take(0)?;

        let combined = rules.iter()
            .map(|r| format!("- [{}] (Priority: {}): {}", r.r#type, r.priority, r.content))
            .collect::<Vec<String>>()
            .join("\n");

        Ok(combined)
    }
}
