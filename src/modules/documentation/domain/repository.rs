#![allow(dead_code)]
use crate::modules::documentation::domain::entity::Documentation;
use async_trait::async_trait;
use anyhow::Result;

#[async_trait]
pub trait DocumentationRepository: Send + Sync {
    async fn find_all(&self) -> Result<Vec<Documentation>>;
    async fn find_by_id(&self, id: &str) -> Result<Option<Documentation>>;
    async fn find_by_project(&self, project_id: &str) -> Result<Vec<Documentation>>;
    async fn find_by_project_and_phase(&self, project_id: &str, phase: &str) -> Result<Vec<Documentation>>;
    async fn create(&self, doc: Documentation) -> Result<Documentation>;
    async fn update(&self, id: &str, doc: Documentation) -> Result<Documentation>;
    async fn delete(&self, id: &str) -> Result<()>;
    async fn search(&self, query: &str) -> Result<Vec<Documentation>>;
}
