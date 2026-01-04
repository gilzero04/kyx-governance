mod core;
mod modules;

use crate::core::config::Config;
use crate::core::transport;
use std::sync::Arc;

#[ntex::main]
async fn main() -> std::io::Result<()> {
    // 1. Load Environment Variables
    dotenvy::dotenv().ok();
    
    // Initialize logging
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .target(env_logger::Target::Stderr)
        .init();
    
    let config = Config::from_env();
    
    log::info!("🛡️ Kyx Governance Hub (Rust/Ntex 2.17) starting...");

    // 2. Connect to Database
    let db = match crate::core::database::connect(&config).await {
        Ok(db) => Arc::new(db),
        Err(e) => {
            log::error!("❌ Failed to connect to SurrealDB: {}", e);
            return Err(std::io::Error::new(std::io::ErrorKind::Other, e.to_string()));
        }
    };
    log::info!("✅ Connected to SurrealDB: {}/{}", config.surreal_ns, config.surreal_db);
    
    // 3. Initialize Vector Store (Phase 3)
    let vector = match crate::core::database::vector::VectorStore::new(&config).await {
        Ok(v) => Arc::new(v),
        Err(e) => {
            log::error!("❌ Failed to initialize Vector Store: {}", e);
            return Err(std::io::Error::new(std::io::ErrorKind::Other, e.to_string()));
        }
    };
    log::info!("✅ Connected to Qdrant: {}", config.qdrant_url);

    // 3.5. Initialize Prometheus Metrics
    crate::core::metrics::init_metrics();

    // 4. Run Migrations (Non-fatal)
    if let Err(e) = crate::core::database::seeder::apply_migrations(&db).await {
        log::warn!("⚠️  Migration check failed (non-fatal): {}", e);
    }

    // 5. Start HTTP Server
    log::info!("🌐 Mode: HTTP only");
    let config = Arc::new(config);
    transport::run_http_server(config.port, db, vector, config).await?;

    Ok(())
}
