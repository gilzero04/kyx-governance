use serde::Deserialize;
use std::env;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub port: u16,
    pub surreal_url: String,
    pub surreal_user: String,
    pub surreal_pass: String,
    pub surreal_ns: String,
    pub surreal_db: String,
    pub mcp_api_key: Option<String>,
    #[allow(dead_code)]
    pub jwt_secret: String,
}

impl Config {
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();

        Self {
            port: env::var("PORT")
                .unwrap_or_else(|_| "3001".to_string())
                .parse()
                .expect("PORT must be a number"),
            surreal_url: env::var("SURREAL_URL")
                .unwrap_or_else(|_| "ws://127.0.0.1:8000/rpc".to_string()),
            surreal_user: env::var("SURREAL_USER").unwrap_or_else(|_| "root".to_string()),
            surreal_pass: env::var("SURREAL_PASS").unwrap_or_else(|_| "c31256bbba78c60c09cfa90c65fb533b96fd1bb27a22be2f".to_string()),
            surreal_ns: env::var("SURREAL_NAMESPACE").unwrap_or_else(|_| "kyx".to_string()),
            surreal_db: env::var("SURREAL_DATABASE").unwrap_or_else(|_| "governance".to_string()),
            // Optional: if set, requires Bearer token authentication
            mcp_api_key: env::var("MCP_API_KEY").ok().filter(|s| !s.is_empty()),
            jwt_secret: env::var("JWT_SECRET").unwrap_or_else(|_| "dev-secret".to_string()),
        }
    }
    
    /// Check if authentication is required
    pub fn requires_auth(&self) -> bool {
        self.mcp_api_key.is_some()
    }
    
    /// Validate the provided API key
    pub fn validate_api_key(&self, key: &str) -> bool {
        match &self.mcp_api_key {
            Some(expected) => key == expected,
            None => true, // No auth required
        }
    }
}
