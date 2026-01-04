use anyhow::{Result, anyhow};
use serde::{Deserialize, Serialize};
use crate::core::config::Config;
use crate::core::rate_limiter::RateLimiter;

// OpenAI API structures
#[derive(Debug, Serialize)]
struct OpenAIEmbeddingRequest {
    model: String,
    input: String,
}

#[derive(Debug, Deserialize)]
struct OpenAIEmbeddingResponse {
    data: Vec<EmbeddingData>,
}

#[derive(Debug, Deserialize)]
struct EmbeddingData {
    embedding: Vec<f32>,
}

// Qdrant REST API structures
#[derive(Debug, Serialize)]
struct QdrantCreateCollection {
    vectors: QdrantVectorParams,
}

#[derive(Debug, Serialize)]
struct QdrantVectorParams {
    size: u64,
    distance: String, // "Cosine", "Euclid", "Dot"
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct QdrantCollectionInfo {
    result: Option<serde_json::Value>,
}

#[derive(Debug, Serialize)]
struct QdrantUpsertPoints {
    points: Vec<QdrantPoint>,
}

#[derive(Debug, Serialize)]
struct QdrantPoint {
    id: String,
    vector: Vec<f32>,
    payload: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct QdrantSearchRequest {
    vector: Vec<f32>,
    limit: u64,
    with_payload: bool,
}

#[derive(Debug, Deserialize)]
struct QdrantSearchResponse {
    result: Vec<QdrantSearchResult>,
}

#[derive(Debug, Deserialize)]
struct QdrantSearchResult {
    id: serde_json::Value,
    score: f64,
    payload: Option<serde_json::Value>,
}

#[derive(Clone)]
pub struct VectorStore {
    qdrant_url: String,
    config: Config,
    http_client: reqwest::Client,
    rate_limiter: RateLimiter,
}

impl VectorStore {
    pub async fn new(config: &Config) -> Result<Self> {
        // Configure HTTP client with proper HTTP/2 support
        let http_client = reqwest::Client::builder()
            .pool_max_idle_per_host(10)
            .pool_idle_timeout(std::time::Duration::from_secs(90))
            .timeout(std::time::Duration::from_secs(60))
            .connect_timeout(std::time::Duration::from_secs(10))
            .build()?;

        Ok(Self {
            qdrant_url: config.qdrant_url.clone(),
            config: config.clone(),
            http_client,
            rate_limiter: RateLimiter::new(),
        })
    }

    pub async fn ensure_collection(&self, collection_name: &str, size: u64) -> Result<()> {
        // Check if collection exists
        let url = format!("{}/collections/{}", self.qdrant_url, collection_name);
        
        let response = self.http_client
            .get(&url)
            .send()
            .await?;

        if response.status().is_success() {
            log::info!("✅ Collection '{}' already exists", collection_name);
            return Ok(());
        }

        // Create collection
        log::info!("📦 Creating collection '{}'...", collection_name);
        
        let create_payload = QdrantCreateCollection {
            vectors: QdrantVectorParams {
                size,
                distance: "Cosine".to_string(),
            },
        };

        let response = self.http_client
            .put(&url)
            .json(&create_payload)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("Failed to create Qdrant collection: {}", error_text));
        }

        log::info!("✅ Collection '{}' created successfully", collection_name);
        Ok(())
    }

    pub async fn get_embedding(&self, text: &str) -> Result<Vec<f32>> {
        if self.config.openai_api_key.is_empty() || self.config.openai_api_key == "sk-placeholder" {
            return Err(anyhow!("OPENAI_API_KEY is not set. Please provide a valid key in .env file."));
        }

        // Check rate limit BEFORE calling OpenAI
        self.rate_limiter.check_openai()?;
        
        log::info!("🔍 Calling OpenAI API for embedding...");
        
        let response = match self.http_client
            .post("https://api.openai.com/v1/embeddings")
            .bearer_auth(&self.config.openai_api_key)
            .json(&OpenAIEmbeddingRequest {
                model: self.config.embedding_model.clone(),
                input: text.to_string(),
            })
            .send()
            .await {
                Ok(r) => {
                    log::info!("✅ OpenAI API responded with status: {}", r.status());
                    r
                },
                Err(e) => {
                    log::error!("❌ OpenAI API request failed: {:?}", e);
                    return Err(anyhow!("OpenAI API request error: {}", e));
                }
            };

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unable to read error".to_string());
            log::error!("❌ OpenAI API error ({}): {}", status, error_text);
            return Err(anyhow!("OpenAI API error ({}): {}", status, error_text));
        }

        let result: OpenAIEmbeddingResponse = response.json().await?;
        result.data.first()
            .map(|d| d.embedding.clone())
            .ok_or_else(|| anyhow!("No embedding returned from OpenAI"))
    }

    pub async fn upsert_document(
        &self, 
        collection_name: &str, 
        id: String, 
        text: &str, 
        metadata: serde_json::Value
    ) -> Result<()> {
        let embedding = self.get_embedding(text).await?;
        
        // Merge content into metadata
        let payload = match metadata {
            serde_json::Value::Object(mut map) => {
                map.insert("content".to_string(), serde_json::Value::String(text.to_string()));
                serde_json::Value::Object(map)
            },
            _ => serde_json::json!({
                "content": text
            }),
        };

        let point = QdrantPoint {
            id,
            vector: embedding,
            payload,
        };

        let upsert_payload = QdrantUpsertPoints {
            points: vec![point],
        };

        let url = format!("{}/collections/{}/points", self.qdrant_url, collection_name);
        
        let response = self.http_client
            .put(&url)
            .json(&upsert_payload)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("Failed to upsert point to Qdrant: {}", error_text));
        }

        Ok(())
    }

    pub async fn search(
        &self, 
        collection_name: &str, 
        query: &str, 
        limit: u64
    ) -> Result<Vec<serde_json::Value>> {
        let embedding = self.get_embedding(query).await?;

        let search_payload = QdrantSearchRequest {
            vector: embedding,
            limit,
            with_payload: true,
        };

        let url = format!("{}/collections/{}/points/search", self.qdrant_url, collection_name);
        
        let response = self.http_client
            .post(&url)
            .json(&search_payload)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("Failed to search Qdrant: {}", error_text));
        }

        let search_response: QdrantSearchResponse = response.json().await?;
        
        let results = search_response.result.into_iter().map(|point| {
            serde_json::json!({
                "id": point.id,
                "score": point.score,
                "payload": point.payload.unwrap_or(serde_json::json!({})),
            })
        }).collect();

        Ok(results)
    }
}
