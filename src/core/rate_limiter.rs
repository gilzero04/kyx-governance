use governor::{Quota, RateLimiter as GovernorRateLimiter, state::{InMemoryState, NotKeyed}, clock::DefaultClock};
use nonzero_ext::nonzero;
// use std::num::NonZeroU32;
use anyhow::{Result, anyhow};
use std::sync::Arc;
use std::collections::HashMap;
use std::sync::Mutex;

/// Rate limiter for controlling API usage and preventing abuse
pub struct RateLimiter {
    // OpenAI API: 60 requests/min (conservative limit)
    openai_limiter: Arc<GovernorRateLimiter<NotKeyed, InMemoryState, DefaultClock>>,
    
    // Database: 1000 requests/min (high limit for internal use)
    db_limiter: Arc<GovernorRateLimiter<NotKeyed, InMemoryState, DefaultClock>>,
    
    // Per-user limits: 100 requests/hour
    user_limiters: Arc<Mutex<HashMap<String, GovernorRateLimiter<NotKeyed, InMemoryState, DefaultClock>>>>,
}

#[allow(dead_code)]
impl RateLimiter {
    pub fn new() -> Self {
        Self {
            openai_limiter: Arc::new(GovernorRateLimiter::direct(
                Quota::per_minute(nonzero!(60u32))
            )),
            db_limiter: Arc::new(GovernorRateLimiter::direct(
                Quota::per_minute(nonzero!(1000u32))
            )),
            user_limiters: Arc::new(Mutex::new(HashMap::new())),
        }
    }
    
    /// Check if OpenAI API call is allowed
    pub fn check_openai(&self) -> Result<()> {
        self.openai_limiter.check()
            .map_err(|_| anyhow!("OpenAI rate limit exceeded (60 requests/min). Please try again later."))?;
        Ok(())
    }
    
    /// Check if database query is allowed
    pub fn check_database(&self) -> Result<()> {
        self.db_limiter.check()
            .map_err(|_| anyhow!("Database rate limit exceeded (1000 requests/min)."))?;
        Ok(())
    }
    
    /// Check if user has exceeded their rate limit
    pub fn check_user(&self, user_id: &str) -> Result<()> {
        let mut limiters = self.user_limiters.lock().unwrap();
        
        let limiter = limiters.entry(user_id.to_string())
            .or_insert_with(|| {
                GovernorRateLimiter::direct(Quota::per_hour(nonzero!(100u32)))
            });
        
        limiter.check()
            .map_err(|_| anyhow!("User rate limit exceeded (100 requests/hour). Please try again later."))?;
        
        Ok(())
    }
    
    /// Get current OpenAI request count (for monitoring)
    pub fn openai_remaining(&self) -> u32 {
        // Note: governor doesn't expose remaining count directly
        // This is a placeholder for future metrics
        60
    }
    
    /// Get current user request count
    pub fn user_remaining(&self, _user_id: &str) -> u32 {
        // Placeholder for future metrics
        100
    }
}

impl Clone for RateLimiter {
    fn clone(&self) -> Self {
        Self {
            openai_limiter: Arc::clone(&self.openai_limiter),
            db_limiter: Arc::clone(&self.db_limiter),
            user_limiters: Arc::clone(&self.user_limiters),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_rate_limiter_creation() {
        let limiter = RateLimiter::new();
        assert!(limiter.check_openai().is_ok());
        assert!(limiter.check_database().is_ok());
        assert!(limiter.check_user("test_user").is_ok());
    }
    
    #[test]
    fn test_openai_rate_limit() {
        let limiter = RateLimiter::new();
        
        // Should allow first 60 requests
        for _ in 0..60 {
            assert!(limiter.check_openai().is_ok());
        }
        
        // 61st request should fail
        assert!(limiter.check_openai().is_err());
    }
    
    #[test]
    fn test_user_rate_limit() {
        let limiter = RateLimiter::new();
        
        // Should allow first 100 requests
        for _ in 0..100 {
            assert!(limiter.check_user("user1").is_ok());
        }
        
        // 101st request should fail
        assert!(limiter.check_user("user1").is_err());
        
        // Different user should still work
        assert!(limiter.check_user("user2").is_ok());
    }
}
