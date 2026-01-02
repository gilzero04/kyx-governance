use std::collections::HashMap;
use std::time::{Duration, Instant};
use std::sync::Mutex;

pub struct RateLimiter {
    // Map: IP -> (WindowStart, RequestCount)
    visitors: Mutex<HashMap<String, (Instant, u32)>>,
    limit: u32,
    window: Duration,
}

impl RateLimiter {
    pub fn new(limit: u32, window_secs: u64) -> Self {
        Self {
            visitors: Mutex::new(HashMap::new()),
            limit,
            window: Duration::from_secs(window_secs),
        }
    }

    pub fn check(&self, ip: String) -> bool {
        let mut visitors = self.visitors.lock().unwrap();
        let entry = visitors.entry(ip).or_insert((Instant::now(), 0));
        
        if entry.0.elapsed() > self.window {
            *entry = (Instant::now(), 0);
        }
        
        entry.1 += 1;
        entry.1 <= self.limit
    }
}

impl Default for RateLimiter {
    fn default() -> Self {
        Self::new(300, 60)
    }
}
