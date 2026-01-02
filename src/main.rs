mod core;
mod modules;

use crate::core::config::Config;
use crate::core::mcp::handler::McpHandler;
use crate::core::mcp::JsonRpcRequest;
use ntex::web;
use std::io::{self, BufRead};
use std::sync::Arc;

#[ntex::main]
async fn main() -> std::io::Result<()> {
    // 1. Load Environment Variables
    dotenvy::dotenv().ok();
    env_logger::init_from_env(env_logger::Env::default().default_filter_or("info"));
    
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

    // 2.1 Run Migrations
    if let Err(e) = crate::core::database::seeder::apply_migrations(&db).await {
        log::error!("❌ Migration failed: {}", e);
        // We decide here if we want to crash or continue. Crashing is safer to prevent data corruption.
        return Err(e);
    }

    // 3. Determine Mode (Stdio, HTTP, or Hybrid)
    let transport = std::env::var("MCP_TRANSPORT").unwrap_or_else(|_| "stdio".to_string());

    match transport.as_str() {
        "stdio" => {
            log::info!("📟 Mode: Stdio only");
            run_stdio_loop((*db).clone()).await?;
        },
        "http" => {
            log::info!("🌐 Mode: HTTP only");
            let config = Arc::new(config);
            run_http_server(config.port, db, config).await?;
        },
        "hybrid" => {
            log::info!("🔀 Mode: Hybrid (Stdio + HTTP)");
            let config = Arc::new(config);
            run_hybrid(config.clone(), db, config).await?;
        },
        _ => {
            log::warn!("⚠️ Unknown transport '{}', defaulting to stdio", transport);
            run_stdio_loop((*db).clone()).await?;
        }
    }

    Ok(())
}

/// Hybrid Mode: Runs HTTP server + Stdio in same thread using ntex runtime
async fn run_hybrid(config: Arc<crate::core::config::Config>, db: Arc<crate::core::database::Database>, config_for_http: Arc<crate::core::config::Config>) -> std::io::Result<()> {
    let db_for_stdio = (*db).clone();
    let port = config.port;
    
    // Spawn Stdio handler in background thread (blocking I/O)
    std::thread::spawn(move || {
        log::info!("📟 Starting Stdio handler in background thread...");
        let handler = McpHandler::new(db_for_stdio);
        run_stdio_blocking(handler);
    });

    // Run HTTP server in main async context
    log::info!("🌐 Starting HTTP server on port {}...", port);
    run_http_server(port, db, config_for_http).await
}

/// Blocking stdio loop for use in a separate thread
fn run_stdio_blocking(handler: McpHandler) {
    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                log::error!("❌ Stdin read error: {}", e);
                break;
            }
        };
        
        if line.trim().is_empty() { continue; }

        log::debug!("📥 Received: {}", line);
        
        let req: Result<JsonRpcRequest, _> = serde_json::from_str(&line);
        
        match req {
            Ok(req) => {
                // Check if this is a notification (no id)
                let is_notification = req.id.is_none();
                
                // Block on async handler using futures executor
                let result = futures::executor::block_on(handler.handle_request(req));
                
                match result {
                    Ok(resp) => {
                        // Per JSON-RPC 2.0: notifications don't get responses
                        if !is_notification {
                            if let Ok(resp_json) = serde_json::to_string(&resp) {
                                println!("{}", resp_json);
                            }
                        }
                    },
                    Err(e) => {
                        log::error!("❌ Error processing request: {}", e);
                    }
                }
            },
            Err(e) => {
                log::error!("❌ Failed to parse JSON-RPC request: {}", e);
            }
        }
    }
}

async fn run_stdio_loop(db: crate::core::database::Database) -> std::io::Result<()> {
    log::info!("📟 Entering Stdio Transport Loop...");
    let handler = McpHandler::new(db);
    
    // Use blocking thread for stdin
    tokio::task::spawn_blocking(move || {
        run_stdio_blocking(handler);
    }).await.map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
    
    Ok(())
}

/// MCP JSON-RPC handler for HTTP POST requests with Bearer token authentication
async fn handle_mcp_request(
    req: web::HttpRequest,
    body: web::types::Json<JsonRpcRequest>,
    db: web::types::State<Arc<crate::core::database::Database>>,
    config: web::types::State<Arc<crate::core::config::Config>>,
) -> web::HttpResponse {
    // Check authentication if MCP_API_KEY is set
    if config.requires_auth() {
        let auth_header = req.headers().get("Authorization");
        
        let is_valid = match auth_header {
            Some(header) => {
                if let Ok(header_str) = header.to_str() {
                    if header_str.starts_with("Bearer ") {
                        let token = &header_str[7..]; // Skip "Bearer "
                        config.validate_api_key(token)
                    } else {
                        false
                    }
                } else {
                    false
                }
            },
            None => false,
        };
        
        if !is_valid {
            return web::HttpResponse::Unauthorized()
                .json(&serde_json::json!({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": -32000,
                        "message": "Unauthorized: Invalid or missing Bearer token"
                    },
                    "id": null
                }));
        }
    }
    
    let handler = McpHandler::new((**db).clone());
    
    match handler.handle_request(body.into_inner()).await {
        Ok(response) => {
            web::HttpResponse::Ok()
                .content_type("application/json")
                .json(&response)
        },
        Err(e) => {
            log::error!("MCP request error: {}", e);
            web::HttpResponse::InternalServerError()
                .json(&serde_json::json!({
                    "jsonrpc": "2.0",
                    "error": {
                        "code": -32603,
                        "message": e.to_string()
                    },
                    "id": null
                }))
        }
    }
}

async fn run_http_server(port: u16, db: Arc<crate::core::database::Database>, config: Arc<crate::core::config::Config>) -> std::io::Result<()> {
    if config.requires_auth() {
        log::info!("🔐 Authentication ENABLED (MCP_API_KEY set)");
    } else {
        log::info!("🔓 Authentication DISABLED (no MCP_API_KEY)");
    }
    log::info!("🌐 Starting HTTP/MCP Server on port {}...", port);
    
    web::server(move || {
        web::App::new()
            .state(db.clone())
            .state(config.clone())
            .wrap(web::middleware::Logger::default())
            // CORS disabled for now - add back with proper config for production
            // Health check endpoint (no auth required)
            .service(web::resource("/health").to(|| async {
                web::HttpResponse::Ok().json(&serde_json::json!({
                    "status": "healthy",
                    "service": "kyx-governance",
                    "version": "0.1.0",
                    "transport": std::env::var("MCP_TRANSPORT").unwrap_or_else(|_| "unknown".to_string()),
                    "auth_required": std::env::var("MCP_API_KEY").is_ok(),
                    "timestamp": chrono::Utc::now().to_rfc3339()
                }))
            }))
            // MCP JSON-RPC endpoint (POST, auth required if MCP_API_KEY set)
            .service(web::resource("/mcp")
                .route(web::post().to(handle_mcp_request)))
            // MCP Root endpoint
            .service(web::resource("/").to(|| async {
                web::HttpResponse::Ok().json(&serde_json::json!({
                    "name": "kyx-governance",
                    "version": "0.1.0",
                    "description": "Kyx Governance Hub - MCP Server",
                    "endpoints": {
                        "health": "GET /health",
                        "mcp": "POST /mcp (JSON-RPC 2.0)"
                    },
                    "auth": "Bearer token (if MCP_API_KEY is set)"
                }))
            }))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
