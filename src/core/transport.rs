use std::sync::Arc;
use std::collections::HashMap;
use std::sync::Mutex;
use ntex::web;
use ntex::util::Bytes;
use tokio::sync::mpsc;
use uuid::Uuid;
use serde::Deserialize;
use crate::core::config::Config;
use crate::core::database::{Database, vector::VectorStore};
use crate::core::mcp::handler::McpHandler;
use crate::core::mcp::JsonRpcRequest;
use crate::core::security::RateLimiter;

lazy_static::lazy_static! {
    static ref SESSIONS: Mutex<HashMap<String, mpsc::UnboundedSender<Bytes>>> = Mutex::new(HashMap::new());
}

/// Standardized response wrapper for non-MCP internal endpoints
fn internal_wrap_response(data: serde_json::Value) -> serde_json::Value {
    serde_json::json!({
        "success": true,
        "data": data,
        "error": null
    })
}

#[derive(Debug, thiserror::Error)]
#[error("SSE error")]
pub struct SseError;

#[derive(Deserialize)]
pub struct McpQuery {
    pub session_id: Option<String>,
}

/// A wrapper for the SSE stream that ensures session cleanup on drop.
struct SseStream {
    rx: mpsc::UnboundedReceiver<Bytes>,
    session_id: String,
}

impl futures::Stream for SseStream {
    type Item = Result<Bytes, SseError>;

    fn poll_next(mut self: std::pin::Pin<&mut Self>, cx: &mut std::task::Context<'_>) -> std::task::Poll<Option<Self::Item>> {
        match self.rx.poll_recv(cx) {
            std::task::Poll::Ready(Some(bytes)) => std::task::Poll::Ready(Some(Ok(bytes))),
            std::task::Poll::Ready(None) => std::task::Poll::Ready(None),
            std::task::Poll::Pending => std::task::Poll::Pending,
        }
    }
}

impl Drop for SseStream {
    fn drop(&mut self) {
        let mut sessions = SESSIONS.lock().unwrap();
        if sessions.remove(&self.session_id).is_some() {
            log::info!("🧹 SSE Session cleaned up: {}", self.session_id);
        }
    }
}
pub async fn handle_mcp_request(
    req: web::HttpRequest,
    query: web::types::Query<McpQuery>,
    body: web::types::Json<JsonRpcRequest>,
    db: web::types::State<Arc<Database>>,
    vector: web::types::State<Arc<VectorStore>>,
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
    
    let handler = McpHandler::new((**db).clone(), (*vector).clone());
    let method = body.method.clone();
    
    let req_id = body.id.clone().unwrap_or(serde_json::json!(null));
    
    match handler.handle_request(body.into_inner()).await {
        Ok(Some(response)) => {
            // 1. Push to SSE as secondary stream if session is active (Standard MCP Spec)
            if let Some(session_id) = &query.session_id {
                let sessions = SESSIONS.lock().unwrap();
                if let Some(tx) = sessions.get(session_id) {
                    // MUST be raw JSON-RPC for SSE too
                    if let Ok(json_str) = serde_json::to_string(&response) {
                        let sse_msg = format!("event: message\ndata: {}\n\n", json_str);
                        let _ = tx.send(Bytes::from(sse_msg)); 
                        log::info!("⚡ Secondary SSE push for session: {}", session_id);
                    }
                }
            }
            
            // 2. ALWAYS return raw JSON-RPC in HTTP response body (Critical for most runtimes)
            log::info!("📤 Handled MCP request (HTTP Body): {}", method);
            web::HttpResponse::Ok().json(&response)
        },
        Ok(None) => {
            log::info!("✉️ Handled notification: {}", method);
            // Return empty-but-valid JSON-RPC instead of 204
            web::HttpResponse::Ok().json(&serde_json::json!({
                "jsonrpc": "2.0",
                "result": "ok"
            }))
        },
        Err(e) => {
            log::error!("🔥 MCP request error: {}", e);
            web::HttpResponse::Ok().json(&serde_json::json!({
                "jsonrpc": "2.0",
                "id": req_id,
                "error": { "code": -32603, "message": e.to_string() }
            }))
        }
    }
}

/// MCP SSE handler for GET requests
pub async fn handle_mcp_sse(
    _req: web::HttpRequest,
    _config: web::types::State<Arc<Config>>,
) -> web::HttpResponse {
    let session_id = Uuid::new_v4().to_string();
    let (tx, rx) = mpsc::unbounded_channel::<Bytes>();
    
    // Build relative URL for discovery (most compatible)
    let endpoint_url = format!("/mcp?session_id={}", session_id);
    log::info!("📡 SSE Connection established. session_id={}, discovery_url={}", session_id, endpoint_url);
    
    // Store session
    {
        let mut sessions = SESSIONS.lock().unwrap();
        sessions.insert(session_id.clone(), tx.clone());
    }
    
    // Initial discovery message (MUST be first)
    let discovery_msg = format!("event: endpoint\ndata: {}\n\n", endpoint_url);
    let _ = tx.send(Bytes::from(discovery_msg));
    
    // Heartbeat task to keep connection alive and workers from timing out
    let tx_heartbeat = tx.clone();
    tokio::spawn(async move {
        loop {
            tokio::time::sleep(tokio::time::Duration::from_secs(30)).await;
            // SSE comment as heartbeat with timestamp for debugging
            let ts = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs();
            let heartbeat_msg = format!(": heartbeat {{\"ts\": {}}}\n\n", ts);
            if tx_heartbeat.send(Bytes::from(heartbeat_msg)).is_err() {
                log::warn!("💔 SSE heartbeat channel closed");
                break;
            }
        }
    });
    
    let stream = SseStream {
        rx,
        session_id,
    };

    web::HttpResponse::Ok()
        .content_type("text/event-stream")
        .header("Cache-Control", "no-cache")
        .header("Connection", "keep-alive")
        .header("X-Accel-Buffering", "no")
        .streaming(Box::pin(stream))
}

/// MCP DELETE handler for session cleanup
pub async fn handle_mcp_delete(
    query: web::types::Query<McpQuery>,
) -> web::HttpResponse {
    let mut removed = false;
    if let Some(session_id) = &query.session_id {
        let mut sessions = SESSIONS.lock().unwrap();
        if sessions.remove(session_id).is_some() {
            log::info!("🗑️ Removed SSE session: {}", session_id);
            removed = true;
        }
    }
    // Agent runtime requires 200 + JSON, not 204
    web::HttpResponse::Ok().json(&internal_wrap_response(serde_json::json!({
        "message": if removed { "Session cleanup successful" } else { "Session not found" },
        "removed": removed
    })))
}

pub async fn run_http_server(
    port: u16, 
    db: Arc<Database>, 
    vector: Arc<VectorStore>,
    config: Arc<Config>
) -> std::io::Result<()> {
    let rate_limiter = Arc::new(RateLimiter::default());
    
    log::info!("🌐 Starting HTTP/MCP Server on port {}...", port);
    
    web::server(move || {
        let cors = ntex_cors::Cors::new()
            .allowed_origin("*")
            .allowed_methods(vec!["GET", "POST", "DELETE", "OPTIONS"])
            .allowed_headers(vec![
                ntex::http::header::AUTHORIZATION,
                ntex::http::header::CONTENT_TYPE,
                ntex::http::header::ACCEPT,
            ])
            .max_age(3600)
            .finish();

        web::App::new()
            .state(db.clone())
            .state(vector.clone())
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
            .service(web::resource("/metrics").to(|| async {
                let metrics_text = crate::core::metrics::get_metrics_text();
                web::HttpResponse::Ok()
                    .content_type("text/plain; version=0.0.4")
                    .body(metrics_text)
            }))
            .service(
                web::resource("/mcp")
                    .route(web::post().to(handle_mcp_request))
                    .route(web::get().to(handle_mcp_sse))
                    .route(web::delete().to(handle_mcp_delete))
            )
    })
    .workers(50)
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
