#![allow(dead_code)]
use crate::core::database::Database;
use crate::modules::documentation::domain::entity::Documentation;
use crate::modules::documentation::domain::repository::DocumentationRepository;
use async_trait::async_trait;
use anyhow::Result;


pub struct SurrealDocumentationRepository {
    db: Database,
}

impl SurrealDocumentationRepository {
    pub fn new(db: Database) -> Self {
        Self { db }
    }
}

#[async_trait]
impl DocumentationRepository for SurrealDocumentationRepository {
    async fn find_all(&self) -> Result<Vec<Documentation>> {
        let docs: Vec<Documentation> = self.db.select("mcp_documentation").await?;
        Ok(docs)
    }

    async fn find_by_id(&self, id: &str) -> Result<Option<Documentation>> {
        let doc: Option<Documentation> = self.db.select(("mcp_documentation", id)).await?;
        Ok(doc)
    }

    async fn find_by_project(&self, project_id: &str) -> Result<Vec<Documentation>> {
        let mut result = self.db.query("SELECT * FROM mcp_documentation WHERE project_id = $project_id ORDER BY sdlc_phase, name")
            .bind(("project_id", project_id.to_string()))
            .await?;
        let docs: Vec<Documentation> = result.take(0)?;
        Ok(docs)
    }

    async fn find_by_project_and_phase(&self, project_id: &str, phase: &str) -> Result<Vec<Documentation>> {
        let mut result = self.db.query("SELECT * FROM mcp_documentation WHERE project_id = $project_id AND sdlc_phase = $phase ORDER BY name")
            .bind(("project_id", project_id.to_string()))
            .bind(("phase", phase.to_string()))
            .await?;
        let docs: Vec<Documentation> = result.take(0)?;
        Ok(docs)
    }

    async fn create(&self, doc: Documentation) -> Result<Documentation> {
        let created: Documentation = self.db.create("mcp_documentation")
            .content(doc)
            .await?
            .expect("Failed to create document");
        Ok(created)
    }

    async fn update(&self, id: &str, doc: Documentation) -> Result<Documentation> {
        let updated: Documentation = self.db.update(("mcp_documentation", id))
            .merge(doc)
            .await?
            .expect("Failed to update document");
        Ok(updated)
    }

    async fn delete(&self, id: &str) -> Result<()> {
        let _: Option<Documentation> = self.db.delete(("mcp_documentation", id)).await?;
        Ok(())
    }

    async fn search(&self, query_str: &str) -> Result<Vec<Documentation>> {
        let mut result = self.db.query("SELECT * FROM mcp_documentation WHERE title CONTAINS $query OR content CONTAINS $query")
            .bind(("query", query_str.to_string()))
            .await?;
        let docs: Vec<Documentation> = result.take(0)?;
        Ok(docs)
    }
}
