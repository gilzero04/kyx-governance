use surrealdb::engine::any::Any;
use surrealdb::Surreal;
use anyhow::Result;
use crate::core::config::Config;

pub mod seeder;
pub mod vector;
pub type Database = Surreal<Any>;

pub async fn connect(config: &Config) -> Result<Database> {
    let db = surrealdb::engine::any::connect(&config.surreal_url).await?;
    
    db.signin(surrealdb::opt::auth::Root {
        username: &config.surreal_user,
        password: &config.surreal_pass,
    }).await?;
    
    db.use_ns(&config.surreal_ns).use_db(&config.surreal_db).await?;
    
    Ok(db)
}
