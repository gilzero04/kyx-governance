use async_trait::async_trait;
use crate::core::database::Database;
use crate::modules::governance::domain::GovernanceDocument;
use crate::modules::governance::repository::GovernanceRepository;
use anyhow::Result;


pub struct SurrealGovernanceRepository {
    db: Database,
}

impl SurrealGovernanceRepository {
    pub fn new(db: Database) -> Self {
        Self { db }
    }
}

#[async_trait]
impl GovernanceRepository for SurrealGovernanceRepository {
    async fn find_document(&self, project: String, phase: String, name: String) -> Result<Option<GovernanceDocument>> {
        let mut result = self.db.query("
            SELECT title, content, project_id.name as project_name, sdlc_phase, name, mimeType 
            FROM mcp_documentation 
            WHERE project_id.name = $project AND sdlc_phase = $phase AND name = $name
        ")
        .bind(("project", project))
        .bind(("phase", phase))
        .bind(("name", name))
        .await?;

        let doc: Option<GovernanceDocument> = result.take(0)?;
        Ok(doc)
    }

    async fn list_documents(&self, _project: Option<String>) -> Result<Vec<GovernanceDocument>> {
        // TODO: Implement project filter if needed
        let mut result = self.db.query("
            SELECT title, content, project_id.name as project_name, sdlc_phase, name, mimeType 
            FROM mcp_documentation
        ").await?;
        
        let docs: Vec<GovernanceDocument> = result.take(0)?;
        Ok(docs)
    }
}
