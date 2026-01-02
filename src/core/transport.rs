use std::sync::Arc;
use std::io::{self, BufRead};
use ntex::web;
use crate::core::config::Config;
use crate::core::database::Database;
use crate::core::mcp::handler::McpHandler;
use crate::core::mcp::JsonRpcRequest;
use crate::core::security::RateLimiter;

/// MCP JSON-RPC handler for HTTP POST requests
pub async fn handle_mcp_request(
    req: web::HttpRequest,
    body: web::types::Json<JsonRpcRequest>,
    db: web::types::State<Arc<Database>>,
    config: web::types::State<Arc<Config>>,
    rate_limiter: web::types::State<Arc<RateLimiter>>,
) -> web::HttpResponse {
    // 1. Rate Limiting Check
    let ip = req.connection_info().host().to_string();
    if !rate_limiter.check(ip.clone()) {
        log::warn!("🚫 Rate limit exceeded for IP: {}", ip);
        return web::HttpResponse::TooManyRequests()
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "error": { "code": -32000, "message": "Rate limit exceeded" },
                "id": null
            }));
    }

    // 2. Authentication Check
    if config.requires_auth() {
        let auth_header = req.headers().get("Authorization");
        let is_valid = match auth_header {
            Some(header) => header.to_str().ok()
                .filter(|s| s.starts_with("Bearer "))
                .map(|s| &s[7..])
                .map(|token| config.validate_api_key(token))
                .unwrap_or(false),
            None => false,
        };
        
        if !is_valid {
            return web::HttpResponse::Unauthorized()
                .json(&serde_json::json!({
                    "jsonrpc": "2.0",
                    "error": { "code": -32000, "message": "Unauthorized" },
                    "id": null
                }));
        }
    }
    
    let handler = McpHandler::new((**db).clone());
    match handler.handle_request(body.into_inner()).await {
        Ok(response) => web::HttpResponse::Ok().json(&response),
        Err(e) => {
            log::error!("MCP request error: {}", e);
            web::HttpResponse::InternalServerError()
                .json(&serde_json::json!({
                    "jsonrpc": "2.0",
                    "error": { "code": -32603, "message": e.to_string() },
                    "id": null
                }))
        }
    }
}

pub async fn run_http_server(port: u16, db: Arc<Database>, config: Arc<Config>) -> std::io::Result<()> {
    let rate_limiter = Arc::new(RateLimiter::default());
    
    log::info!("🌐 Starting HTTP/MCP Server on port {}...", port);
    
    web::server(move || {
        let cors = ntex_cors::Cors::new()
            .allowed_origin("https://studio.apollographql.com")
            .allowed_origin("http://localhost:3000")
            .allowed_methods(vec!["GET", "POST", "OPTIONS"])
            .allowed_headers(vec![
                ntex::http::header::AUTHORIZATION,
                ntex::http::header::CONTENT_TYPE,
                ntex::http::header::ACCEPT,
            ])
            .max_age(3600)
            .finish();

        web::App::new()
            .state(db.clone())
            .state(config.clone())
            .state(rate_limiter.clone())
            .wrap(web::middleware::Logger::default())
            .wrap(cors)
            .service(web::resource("/health").to(|| async {
                 web::HttpResponse::Ok().json(&serde_json::json!({
                    "status": "healthy",
                    "service": "kyx-governance",
                    "version": "0.1.0"
                }))
            }))
            .service(web::resource("/mcp").route(web::post().to(handle_mcp_request)))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}

pub async fn run_stdio_loop(db: Database) -> std::io::Result<()> {
    log::info!("📟 Entering Stdio Transport Loop...");
    let handler = McpHandler::new(db);
    
    // Create a channel to bridge blocking stdin and async handler
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<String>();

    // Spawn a standard thread to read stdin (blocking)
    std::thread::spawn(move || {
        let stdin = io::stdin();
        for line in stdin.lock().lines() {
            if let Ok(l) = line {
                if tx.send(l).is_err() { 
                    break; // Receiver dropped, stop reading
                }
            }
        }
    });
    
    // Process requests in the main async runtime
    while let Some(line) = rx.recv().await {
        if line.trim().is_empty() { continue; }
        
        log::debug!("📨 Stdio Input: {}", line);
        
        match serde_json::from_str::<JsonRpcRequest>(&line) {
            Ok(req) => {
                let is_notification = req.id.is_none();
                // Execute in proper async context with reactor access
                match handler.handle_request(req).await {
                    Ok(resp) => {
                        if !is_notification {
                             if let Ok(json) = serde_json::to_string(&resp) { 
                                 // HIGHLY IMPORTANT: Write to stdout and flush immediately
                                 // Use writeln! to ensure newline, and flush to ensure it hits the pipe
                                 use std::io::Write;
                                 let mut stdout = std::io::stdout();
                                 if let Err(e) = writeln!(stdout, "{}", json) {
                                     log::error!("Failed to write to stdout: {}", e);
                                 }
                                 let _ = stdout.flush();
                             }
                        }
                    },
                    Err(e) => {
                         log::error!("Handler failed: {}", e);
                    }
                }
            },
            Err(e) => {
                log::error!("Failed to parse JSON-RPC: {}", e);
            }
        }
    }
    
    Ok(())
}

pub async fn run_hybrid(config: Arc<Config>, db: Arc<Database>, config_for_http: Arc<Config>) -> std::io::Result<()> {
    let db_stdio = (*db).clone();
    let port = config.port;
    
    ntex::rt::spawn(async move {
        if let Err(e) = run_stdio_loop(db_stdio).await {
            log::error!("🔥 Stdio loop crashed: {}", e);
        }
    });

    // Run HTTP (blocks the main execution flow)
    run_http_server(port, db, config_for_http).await
}
