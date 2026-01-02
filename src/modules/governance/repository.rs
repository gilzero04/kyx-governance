use async_trait::async_trait;
use crate::modules::governance::domain::GovernanceDocument;
use anyhow::Result;

#[async_trait]
pub trait GovernanceRepository: Send + Sync {
    async fn find_document(&self, project: String, phase: String, name: String) -> Result<Option<GovernanceDocument>>;
    async fn list_documents(&self, project: Option<String>) -> Result<Vec<GovernanceDocument>>;
}
