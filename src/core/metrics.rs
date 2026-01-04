use prometheus::{
    Counter, Histogram, IntCounter, IntGauge, Registry,
    HistogramOpts, Encoder, TextEncoder,
};
use lazy_static::lazy_static;

lazy_static! {
    /// Global Prometheus registry
    pub static ref REGISTRY: Registry = Registry::new();
    
    // ========================================================================
    // Tool Call Metrics
    // ========================================================================
    
    /// Total number of MCP tool calls
    pub static ref TOOL_CALLS_TOTAL: IntCounter = IntCounter::new(
        "mcp_tool_calls_total",
        "Total number of MCP tool calls"
    ).unwrap();
    
    /// Total number of tool call errors
    pub static ref TOOL_ERRORS_TOTAL: IntCounter = IntCounter::new(
        "mcp_tool_errors_total",
        "Total number of tool call errors"
    ).unwrap();
    
    /// Tool call duration in seconds
    pub static ref TOOL_DURATION: Histogram = Histogram::with_opts(
        HistogramOpts::new(
            "mcp_tool_duration_seconds",
            "Tool call duration in seconds"
        )
    ).unwrap();
    
    // ========================================================================
    // OpenAI API Metrics
    // ========================================================================
    
    /// Total OpenAI API requests
    pub static ref OPENAI_REQUESTS_TOTAL: IntCounter = IntCounter::new(
        "mcp_openai_requests_total",
        "Total OpenAI API requests"
    ).unwrap();
    
    /// Total OpenAI tokens used
    pub static ref OPENAI_TOKENS_TOTAL: IntCounter = IntCounter::new(
        "mcp_openai_tokens_total",
        "Total OpenAI tokens used"
    ).unwrap();
    
    /// Estimated OpenAI cost in USD
    pub static ref OPENAI_COST_USD: Counter = Counter::new(
        "mcp_openai_cost_usd",
        "Estimated OpenAI cost in USD"
    ).unwrap();
    
    // ========================================================================
    // Session Metrics
    // ========================================================================
    
    /// Number of active sessions
    pub static ref ACTIVE_SESSIONS: IntGauge = IntGauge::new(
        "mcp_active_sessions",
        "Number of active sessions"
    ).unwrap();
    
    /// Total sessions created
    pub static ref SESSIONS_CREATED_TOTAL: IntCounter = IntCounter::new(
        "mcp_sessions_created_total",
        "Total sessions created"
    ).unwrap();
    
    // ========================================================================
    // Database Metrics
    // ========================================================================
    
    /// Total database queries
    pub static ref DB_QUERIES_TOTAL: IntCounter = IntCounter::new(
        "mcp_db_queries_total",
        "Total database queries"
    ).unwrap();
    
    /// Database query duration
    pub static ref DB_QUERY_DURATION: Histogram = Histogram::with_opts(
        HistogramOpts::new(
            "mcp_db_query_duration_seconds",
            "Database query duration in seconds"
        )
    ).unwrap();
}

/// Initialize all metrics and register with Prometheus
pub fn init_metrics() {
    // Tool metrics
    REGISTRY.register(Box::new(TOOL_CALLS_TOTAL.clone())).unwrap();
    REGISTRY.register(Box::new(TOOL_ERRORS_TOTAL.clone())).unwrap();
    REGISTRY.register(Box::new(TOOL_DURATION.clone())).unwrap();
    
    // OpenAI metrics
    REGISTRY.register(Box::new(OPENAI_REQUESTS_TOTAL.clone())).unwrap();
    REGISTRY.register(Box::new(OPENAI_TOKENS_TOTAL.clone())).unwrap();
    REGISTRY.register(Box::new(OPENAI_COST_USD.clone())).unwrap();
    
    // Session metrics
    REGISTRY.register(Box::new(ACTIVE_SESSIONS.clone())).unwrap();
    REGISTRY.register(Box::new(SESSIONS_CREATED_TOTAL.clone())).unwrap();
    
    // Database metrics
    REGISTRY.register(Box::new(DB_QUERIES_TOTAL.clone())).unwrap();
    REGISTRY.register(Box::new(DB_QUERY_DURATION.clone())).unwrap();
    
    log::info!("📊 Prometheus metrics initialized");
}

/// Track a tool call with duration and success status
#[allow(dead_code)]
pub fn track_tool_call(tool_name: &str, duration_ms: u64, success: bool) {
    TOOL_CALLS_TOTAL.inc();
    TOOL_DURATION.observe(duration_ms as f64 / 1000.0);
    
    if !success {
        TOOL_ERRORS_TOTAL.inc();
    }
    
    log::debug!("📊 Tool: {}, Duration: {}ms, Success: {}", tool_name, duration_ms, success);
}

/// Track OpenAI API usage and calculate cost
#[allow(dead_code)]
pub fn track_openai_usage(tokens: u32) {
    OPENAI_REQUESTS_TOTAL.inc();
    OPENAI_TOKENS_TOTAL.inc_by(tokens as u64);
    
    // text-embedding-3-small: $0.02 per 1M tokens
    let cost = (tokens as f64 / 1_000_000.0) * 0.02;
    OPENAI_COST_USD.inc_by(cost);
    
    log::info!("💰 OpenAI: {} tokens, ${:.6} cost", tokens, cost);
}

/// Track session creation
#[allow(dead_code)]
pub fn track_session_created() {
    SESSIONS_CREATED_TOTAL.inc();
    ACTIVE_SESSIONS.inc();
}

/// Track session expiration/deletion
#[allow(dead_code)]
pub fn track_session_ended() {
    ACTIVE_SESSIONS.dec();
}

/// Track database query
#[allow(dead_code)]
pub fn track_db_query(duration_ms: u64) {
    DB_QUERIES_TOTAL.inc();
    DB_QUERY_DURATION.observe(duration_ms as f64 / 1000.0);
}

/// Get metrics in Prometheus text format
pub fn get_metrics_text() -> String {
    let encoder = TextEncoder::new();
    let metric_families = REGISTRY.gather();
    let mut buffer = vec![];
    encoder.encode(&metric_families, &mut buffer).unwrap();
    String::from_utf8(buffer).unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_metrics_initialization() {
        init_metrics();
        // Should not panic
    }
    
    #[test]
    fn test_tool_tracking() {
        track_tool_call("test-tool", 100, true);
        assert!(TOOL_CALLS_TOTAL.get() > 0);
    }
    
    #[test]
    fn test_openai_cost_calculation() {
        let initial_cost = OPENAI_COST_USD.get();
        track_openai_usage(1_000_000); // 1M tokens
        let new_cost = OPENAI_COST_USD.get();
        
        // Should increase by $0.02
        assert!((new_cost - initial_cost - 0.02).abs() < 0.001);
    }
}
