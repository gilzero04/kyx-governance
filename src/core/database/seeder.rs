use crate::core::database::Database;
use std::fs;
use std::path::Path;

const MIGRATION_DIR: &str = "/migrations";

#[derive(serde::Deserialize)]
struct MigrationRecord {
    id: surrealdb::sql::Thing,
    name: String,
    applied_at: chrono::DateTime<chrono::Utc>,
}

pub async fn apply_migrations(db: &Database) -> std::io::Result<()> {
    log::info!("🔄 Checking for pending migrations in {}...", MIGRATION_DIR);

    // 1. Ensure _migrations table exists
    let _ = db.query("DEFINE TABLE _migrations SCHEMAFULL;").await;
    let _ = db.query("DEFINE FIELD name ON _migrations TYPE string;").await;
    let _ = db.query("DEFINE FIELD applied_at ON _migrations TYPE datetime DEFAULT time::now();").await;
    let _ = db.query("DEFINE INDEX migration_name ON _migrations FIELDS name UNIQUE;").await;

    // 2. Read all files in migrations directory
    let entries = fs::read_dir(MIGRATION_DIR).map_err(|e| {
        log::error!("❌ Failed to read migration directory: {}", e);
        e
    })?;

    let mut migration_files: Vec<String> = Vec::new();
    for entry in entries {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            if let Some(ext) = path.extension() {
                if ext == "surql" {
                    if let Some(file_name) = path.file_name() {
                        if let Some(name_str) = file_name.to_str() {
                            migration_files.push(name_str.to_string());
                        }
                    }
                }
            }
        }
    }

    // 3. Sort files to ensure deterministic order
    migration_files.sort();

    // 4. Iterate and apply
    for file_name in migration_files {
        // Check if already applied
        let check_query = format!("SELECT * FROM _migrations WHERE name = '{}'", file_name);
        
        let mut response = db.query(&check_query).await.map_err(|e| {
            log::error!("❌ Failed to check migration status for {}: {}", file_name, e);
            std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
        })?;
        
        // Use unchecked take because we know the schema
        let existing: Vec<MigrationRecord> = response.take(0).map_err(|e| {
             log::error!("❌ Failed to parse migration check response: {}", e);
             std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
        })?;

        if !existing.is_empty() {
            log::debug!("⏭️  Skipping applied migration: {}", file_name);
            continue;
        }

        // Apply migration
        log::info!("🚀 Applying migration: {}", file_name);
        let content = fs::read_to_string(Path::new(MIGRATION_DIR).join(&file_name))?;
        
        // Execute the migration content
        let mut response = match db.query(&content).await {
            Ok(resp) => resp,
            Err(e) => {
                log::error!("❌ Transport error applying migration {}: {}", file_name, e);
                return Err(std::io::Error::new(std::io::ErrorKind::Other, e.to_string()));
            }
        };

        // Check for errors in individual statements
        // db.query() returns a Response which contains a list of results for each statement
        // We must check faults for each statement.
        let errors = response.take_errors();
        if !errors.is_empty() {
            for (index, err) in errors.iter() {
                log::error!("❌ Error in migration {} (stmt {}): {}", file_name, index, err);
            }
            return Err(std::io::Error::new(std::io::ErrorKind::Other, format!("Migration {} failed with {} errors", file_name, errors.len())));
        }

        // Record as applied
        let record_query = format!(
            "CREATE _migrations CONTENT {{ name: '{}', applied_at: time::now() }};", 
            file_name
        );
        if let Err(e) = db.query(&record_query).await {
            log::error!("❌ Failed to record migration {}: {}", file_name, e);
             return Err(std::io::Error::new(std::io::ErrorKind::Other, e.to_string()));
        }
        
        log::info!("✅ Successfully applied migration: {}", file_name);
    }

    log::info!("✨ All migrations checked/applied.");
    Ok(())
}
