use crate::core::database::{Database, vector::VectorStore};
use crate::core::mcp::{JsonRpcRequest, JsonRpcResponse, McpInitializeResult, ServerInfo, JsonRpcError};
use crate::core::mcp::types::{Resource, ResourceContent, Tool};
use crate::core::mcp::rules::RuleManager;
use serde_json::json;
use anyhow::Result;
use url::Url;
use std::time::Instant;
use std::sync::Arc;

pub struct McpHandler {
    db: Database,
    rules: RuleManager,
    vector: Arc<VectorStore>,
}

impl McpHandler {
    pub fn new(db: Database, vector: Arc<VectorStore>) -> Self {
        Self { 
            db: db.clone(), 
            rules: RuleManager::new(db),
            vector,
        }
    }

    pub async fn handle_request(&self, req: JsonRpcRequest) -> Result<Option<JsonRpcResponse>> {
        let is_notification = req.id.is_none();
        let id = req.id.clone().unwrap_or(json!(null));
        
        let result = match req.method.as_str() {
            "initialize" => self.handle_initialize(req).await,
            "tools/list" => self.handle_tools_list(req).await,
            "resources/list" => self.handle_resources_list(req).await,
            "resources/read" => self.handle_resources_read(req).await,
            "tools/call" => self.handle_tools_call(req).await,
            // Notifications - no response needed (MCP spec: notifications don't expect replies)
            "notifications/initialized" | 
            "notifications/cancelled" |
            "notifications/progress" |
            "notifications/message" => {
                log::info!("📨 Received notification: {}", req.method);
                return Ok(None);
            },
            _ => {
                if is_notification {
                    return Ok(None);
                }
                return Ok(Some(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id,
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32601,
                        message: format!("Method not found: {}", req.method),
                        data: None,
                    }),
                }));
            }
        };

        if is_notification {
            return Ok(None);
        }

        match result {
            Ok(resp) => Ok(Some(resp)),
            Err(e) => {
                log::error!("🔥 Error handling MCP request: {}", e);
                Ok(Some(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id,
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32000,
                        message: e.to_string(),
                        data: None,
                    }),
                }))
            }
        }
    }

    async fn handle_initialize(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
        let result = McpInitializeResult {
            protocol_version: "2024-11-05".to_string(),
            capabilities: json!({
                "tools": {},
                "resources": {},
                "prompts": {}
            }),
            server_info: ServerInfo {
                name: "Kyx Governance Hub".to_string(),
                version: "0.1.0".to_string(),
            },
        };

        Ok(JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: req.id.unwrap_or(json!(null)),
            result: Some(json!(result)),
            error: None,
        })
    }

    async fn handle_tools_list(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
        let mut result = self.db.query("SELECT name, title, description, input_schema, execution_type, sql_template, parameter_map, type::string(project_id) as project_id FROM mcp_tools WHERE active = true").await?;
        
        let mut tools: Vec<Tool> = match result.take::<Vec<Tool>>(0) {
            Ok(tools) => {
                log::info!("✅ Successfully fetched {} tools from database", tools.len());
                tools
            },
            Err(e) => {
                log::error!("🔥 Error deserializing tools from database: {}. This usually indicates a schema mismatch or invalid data in the mcp_tools table.", e);
                Vec::new()
            }
        };

        // If no tools in database, provide a default hardcoded tool
        if tools.is_empty() {
             tools.push(Tool {
                name: "search-governance".to_string(),
                title: Some("Search Governance Documents".to_string()),
                description: "Search through governance standards and SDLC documentation".to_string(),
                input_schema: json!({
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "Search query for governance documentation"
                        }
                    },
                    "required": ["query"]
                }),
                execution_type: Some("static".to_string()),
                sql_template: None,
                parameter_map: None,
                project_id: None,
            });
        }

        Ok(JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: req.id.unwrap_or(json!(null)),
            result: Some(json!({ "tools": tools })),
            error: None,
        })
    }

    async fn handle_resources_list(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
        use crate::modules::governance::repository::GovernanceRepository;
        use crate::modules::governance::infrastructure::SurrealGovernanceRepository;
        
        let repo = SurrealGovernanceRepository::new(self.db.clone());
        let docs = repo.list_documents(None).await?;
        
        let resources: Vec<Resource> = docs.iter().map(|doc| {
            Resource {
                uri: format!("kyx://{}/{}/{}", doc.project_name, doc.sdlc_phase, doc.name),
                name: doc.title.clone(),
                description: Some(format!("SDLC Document for {} in {} phase", doc.project_name, doc.sdlc_phase)),
                mime_type: Some(doc.mime_type.clone()),
            }
        }).collect();

        Ok(JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: req.id.unwrap_or(json!(null)),
            result: Some(json!({ "resources": resources })),
            error: None,
        })
    }

    async fn handle_resources_read(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
        use crate::modules::governance::repository::GovernanceRepository;
        use crate::modules::governance::infrastructure::SurrealGovernanceRepository;

        let params = req.params.as_ref().ok_or_else(|| anyhow::anyhow!("Missing params"))?;
        let uri = params.get("uri").and_then(|v| v.as_str()).ok_or_else(|| anyhow::anyhow!("Missing uri"))?;
        
        let parsed_url = Url::parse(uri)?;
        let project_name = parsed_url.host_str().ok_or_else(|| anyhow::anyhow!("Invalid project in URI"))?;
        let mut path_segments = parsed_url.path_segments().ok_or_else(|| anyhow::anyhow!("Invalid path in URI"))?;
        let sdlc_phase = path_segments.next().ok_or_else(|| anyhow::anyhow!("Missing phase in URI"))?;
        let doc_name = path_segments.next().ok_or_else(|| anyhow::anyhow!("Missing doc_name in URI"))?;

        let repo = SurrealGovernanceRepository::new(self.db.clone());
        let doc_opt = repo.find_document(project_name.to_string(), sdlc_phase.to_string(), doc_name.to_string()).await?;

        match doc_opt {
            Some(doc) => {
                // Fetch and prepend rules (Legacy rule logic kept for now, should move to RuleRepository)
                let rules = self.rules.get_combined_rules(Some(project_name)).await?;
                let final_content = if !rules.is_empty() {
                    format!("## Governance Rules\n\n{}\n\n---\n\n## Content\n\n{}", rules, doc.content)
                } else {
                    doc.content.to_string()
                };

                Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id: req.id.unwrap_or(json!(null)),
                    result: Some(json!({
                        "contents": [
                            ResourceContent {
                                uri: uri.to_string(),
                                mime_type: Some(doc.mime_type),
                                text: Some(final_content),
                                blob: None,
                            }
                        ]
                    })),
                    error: None,
                })
            },
            None => {
                Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id: req.id.unwrap_or(json!(null)),
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32001,
                        message: "Resource not found".to_string(),
                        data: None,
                    }),
                })
            }
        }
    }

    async fn record_audit_log(
        &self,
        tool_name: &str,
        tool_project_id: Option<serde_json::Value>,
        arguments: &serde_json::Value,
        status: &str,
        message: &str,
        duration_ms: i64,
    ) {
        // Try to get project_id from tool definition first, then fallback to arguments
        let mut bind_project: Option<surrealdb::sql::Thing> = None;

        if let Some(pid_val) = tool_project_id {
            if let Some(s) = pid_val.as_str() {
                if let Ok(thing) = surrealdb::sql::thing(s) {
                    bind_project = Some(thing);
                }
            } else if let Ok(thing) = serde_json::from_value::<surrealdb::sql::Thing>(pid_val.clone()) {
                bind_project = Some(thing);
            }
        }

        if bind_project.is_none() {
            if let Some(p_arg) = arguments.get("project").or_else(|| arguments.get("project_id")) {
                if let Some(s) = p_arg.as_str() {
                    if let Ok(thing) = surrealdb::sql::thing(s) {
                        bind_project = Some(thing);
                    } else {
                        // Lookup by name
                         let mut p_query = self.db.query("SELECT id FROM mcp_projects WHERE name = $name LIMIT 1")
                            .bind(("name", s.to_string()))
                            .await.ok();
                        if let Some(mut pq) = p_query {
                            let ids: Vec<serde_json::Value> = pq.take(0).unwrap_or_default();
                            if let Some(first) = ids.first() {
                                if let Some(id_val) = first.get("id") {
                                    if let Ok(thing) = serde_json::from_value::<surrealdb::sql::Thing>(id_val.clone()) {
                                        bind_project = Some(thing);
                                    } else if let Some(id_str) = id_val.as_str() {
                                        if let Ok(thing) = surrealdb::sql::thing(id_str) {
                                            bind_project = Some(thing);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        let query = if bind_project.is_some() {
            "CREATE mcp_audit_log SET tool_name = $tool, project_id = $project, arguments = $args, status = $status, message = $msg, duration_ms = $duration_ms"
        } else {
            "CREATE mcp_audit_log SET tool_name = $tool, arguments = $args, status = $status, message = $msg, duration_ms = $duration_ms"
        };

        let mut insert = self.db.query(query)
            .bind(("tool", tool_name.to_string()))
            .bind(("args", arguments.clone()))
            .bind(("status", status.to_string()))
            .bind(("msg", message.to_string()))
            .bind(("duration_ms", duration_ms));
            
        if let Some(p) = bind_project {
            insert = insert.bind(("project", p));
        }

        if let Err(e) = insert.await {
            log::error!("🔥 Failed to record audit log for {}: {}", tool_name, e);
        }
    }

    async fn handle_tools_call(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
        let params = req.params.as_ref().ok_or_else(|| anyhow::anyhow!("Missing params"))?;
        let name = params.get("name").and_then(|v| v.as_str()).ok_or_else(|| anyhow::anyhow!("Missing name"))?;
        let arguments = params.get("arguments").ok_or_else(|| anyhow::anyhow!("Missing arguments"))?;

        let start = Instant::now();
        log::info!("🛠️ Dispatching tool call: {}", name);

        // Static Tool Dispatch (Phase 3)
        match name {
            "search-semantic" => return self.handle_search_semantic(&req, arguments, start).await,
            "index-documents" => return self.handle_index_documents(&req, arguments, start).await,
            _ => {}
        }

        // Try to find a dynamic tool in the database
        let mut tool_query = self.db.query("SELECT name, title, description, input_schema, execution_type, sql_template, parameter_map, type::string(project_id) as project_id FROM mcp_tools WHERE name = $name AND active = true")
            .bind(("name", name.to_string()))
            .await?;
        
        let mut tools: Vec<Tool> = tool_query.take::<Vec<Tool>>(0).unwrap_or_default();
        
        if let Some(tool) = tools.pop() {
            if let Some(exec_type) = &tool.execution_type {
            if exec_type == "raw_sql" {
                // Execute arbitrary SQL from arguments
                let sql = arguments.get("sql_commands")
                    .and_then(|v| v.as_str())
                    .or_else(|| arguments.get("sql").and_then(|v| v.as_str()))
                    .ok_or_else(|| anyhow::anyhow!("Missing 'sql_commands' or 'sql' argument for raw_sql execution"))?;

                log::info!("🚀 Executing Raw SQL Tool: {}", name);
                let mut result = match self.db.query(sql).await {
                    Ok(r) => r,
                    Err(e) => {
                        let duration_ms = start.elapsed().as_millis() as i64;
                        self.record_audit_log(name, tool.project_id.clone(), arguments, "error", &format!("SQL Error: {}", e), duration_ms).await;
                        return Err(e.into());
                    }
                };
                
                let mut all_results = Vec::new();
                let mut i: usize = 0;
                
                // Collect results from all statements
                while let Ok(vals) = result.take::<Vec<serde_json::Value>>(i) {
                    if vals.is_empty() {
                        break; 
                    }
                    for v in vals {
                        if !v.is_null() {
                            all_results.push(v);
                        }
                    }
                    i += 1;
                }


                // If no array results, try taking as a single value (for INFO, RETURN, etc.)
                if all_results.is_empty() {
                    if let Ok(v) = result.take::<surrealdb::Value>(0) {
                        let val = match serde_json::to_value(&v) {
                            Ok(jv) => jv,
                            Err(_) => serde_json::json!(v.to_string())
                        };
                        if !val.is_null() {
                            all_results.push(val);
                        }
                    }
                }

                // Helper to flatten SurrealDB 2.x ENUM-style serialization
                fn flatten_v(v: serde_json::Value) -> serde_json::Value {
                    match v {
                        serde_json::Value::Object(mut map) => {
                            if map.len() == 1 {
                                let key = map.keys().next().unwrap().clone();
                                if ["Array", "Object", "Strand", "Number", "Bool", "Record"].contains(&key.as_str()) {
                                    let inner = map.remove(&key).unwrap();
                                    return flatten_v(inner);
                                }
                            }
                            let mut new_map = serde_json::Map::new();
                            for (k, v) in map {
                                new_map.insert(k, flatten_v(v));
                            }
                            serde_json::Value::Object(new_map)
                        },
                        serde_json::Value::Array(arr) => {
                            serde_json::Value::Array(arr.into_iter().map(flatten_v).collect())
                        },
                        _ => v
                    }
                }

                let final_results: Vec<serde_json::Value> = all_results.into_iter().map(flatten_v).collect();
                
                let text_output = if final_results.len() == 1 && final_results[0].is_string() {
                    final_results[0].as_str().unwrap_or("").to_string()
                } else {
                    let json_output = serde_json::to_string_pretty(&final_results)?;
                    format!("Raw SQL Result:\n```json\n{}\n```", json_output)
                };

                let duration_ms = start.elapsed().as_millis() as i64;
                self.record_audit_log(name, tool.project_id.clone(), arguments, "success", "Raw SQL executed", duration_ms).await;

                return Ok(JsonRpcResponse::success(
                    json!(crate::core::mcp::types::CallToolResult {
                        content: vec![crate::core::mcp::types::ToolContent {
                            content_type: "text".to_string(),
                            text: Some(text_output),
                            image: None,
                        }],
                        is_error: Some(false),
                    }),
                    req.id.clone()
                ));
            }

            if exec_type == "dynamic_sql" {
                    if let Some(sql) = &tool.sql_template {
                        // Dynamic execution
                        log::info!("🚀 Executing Dynamic Tool: {}", name);
                        
                        let mut query = self.db.query(sql);

                        // Map parameters
                        if let Some(param_map_val) = &tool.parameter_map {
                            // Convert surrealdb::Value to serde_json::Value or Map
                            let param_map_json = serde_json::to_value(param_map_val).unwrap_or(serde_json::json!({}));
                            
                            if let Some(param_map) = param_map_json.as_object() {
                                for (arg_key, sql_var) in param_map {
                                    if let Some(sql_var_str) = sql_var.as_str() {
                                        if let Some(val) = arguments.get(&arg_key) {
                                            // Bind matching argument to SQL variable
                                            match val {
                                                serde_json::Value::String(s) => {
                                                    // Try to parse string as a SurrealDB Thing (Record ID)
                                                    if let Ok(thing) = surrealdb::sql::thing(s) {
                                                        query = query.bind((sql_var_str.to_string(), thing));
                                                    } else {
                                                        query = query.bind((sql_var_str.to_string(), s.to_string()));
                                                    }
                                                },
                                                serde_json::Value::Number(n) => {
                                                    if let Some(i) = n.as_i64() {
                                                        query = query.bind((sql_var_str.to_string(), i));
                                                    } else if let Some(f) = n.as_f64() {
                                                        query = query.bind((sql_var_str.to_string(), f));
                                                    } else {
                                                        // Fallback for extremely large numbers or unknown formats
                                                        query = query.bind((sql_var_str.to_string(), n.to_string()));
                                                    }
                                                },
                                                serde_json::Value::Bool(b) => {
                                                    query = query.bind((sql_var_str.to_string(), *b));
                                                },
                                                _ => {
                                                    // For Objects/Arrays, bind as is (SurrealDB handles JSON)
                                                    query = query.bind((sql_var_str.to_string(), val.clone()));
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        let mut result = match query.await {
                            Ok(r) => r,
                            Err(e) => {
                                log::error!("🔥 Execution Error for {}: {}", name, e);
                                let duration_ms = start.elapsed().as_millis() as i64;
                                self.record_audit_log(name, tool.project_id.clone(), arguments, "error", &format!("Execution Error: {}", e), duration_ms).await;
                                return Err(e.into());
                            }
                        };
                    
                    log::info!("✅ Query executed for {}, collecting results", name);
                    let mut all_results = Vec::new();
                    let mut i: usize = 0;
                    
                    // Collect results from all statements
                    while let Ok(vals) = result.take::<Vec<serde_json::Value>>(i) {
                        if vals.is_empty() {
                            // Check if the individual result set at this index itself was null
                            // In SurrealDB 2.x, result.take(i) might return Ok(vec![null]) for a LET statement
                            break; 
                        }
                        for v in vals {
                            if !v.is_null() {
                                all_results.push(v);
                            }
                        }
                        i += 1;
                    }


                    // If no array results, try taking as a single value
                    if all_results.is_empty() {
                        if let Ok(v) = result.take::<surrealdb::Value>(0) {
                            let val = match serde_json::to_value(&v) {
                                Ok(jv) => jv,
                                Err(_) => serde_json::json!(v.to_string())
                            };
                            if !val.is_null() {
                                all_results.push(val);
                            }
                        }
                    }

                    // Helper to flatten SurrealDB 2.x ENUM-style serialization
                    fn flatten_v(v: serde_json::Value) -> serde_json::Value {
                        match v {
                            serde_json::Value::Object(mut map) => {
                                if map.len() == 1 {
                                    let key = map.keys().next().unwrap().clone();
                                    if ["Array", "Object", "Strand", "Number", "Bool", "Record"].contains(&key.as_str()) {
                                        let inner = map.remove(&key).unwrap();
                                        return flatten_v(inner);
                                    }
                                }
                                let mut new_map = serde_json::Map::new();
                                for (k, v) in map {
                                    new_map.insert(k, flatten_v(v));
                                }
                                serde_json::Value::Object(new_map)
                            },
                            serde_json::Value::Array(arr) => {
                                serde_json::Value::Array(arr.into_iter().map(flatten_v).collect())
                            },
                            _ => v
                        }
                    }

                    let final_results: Vec<serde_json::Value> = all_results.into_iter().map(flatten_v).collect();

                    log::info!("✅ Results collected for {}: {} items", name, final_results.len());

                    let text_output = if final_results.len() == 1 && final_results[0].is_string() {
                        final_results[0].as_str().unwrap_or("").to_string()
                    } else {
                        let json_output = serde_json::to_string_pretty(&final_results)?;
                        format!("Dynamic Tool Result:\n```json\n{}\n```", json_output)
                    };

                    let duration_ms = start.elapsed().as_millis() as i64;
                    self.record_audit_log(name, tool.project_id.clone(), arguments, "success", "Dynamic SQL executed", duration_ms).await;

                    return Ok(JsonRpcResponse::success(
                        json!(crate::core::mcp::types::CallToolResult {
                            content: vec![crate::core::mcp::types::ToolContent {
                                content_type: "text".to_string(),
                                text: Some(text_output),
                                image: None,
                            }],
                            is_error: Some(false),
                        }),
                        req.id.clone()
                    ));
                    }
                }
            }
        }

        // If no tool found
        let duration_ms = start.elapsed().as_millis() as i64;
        self.record_audit_log(name, None, arguments, "error", &format!("Tool not found: {}", name), duration_ms).await;

        Ok(JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: req.id.unwrap_or(json!(null)),
            result: None,
            error: Some(JsonRpcError {
                code: -32601,
                message: format!("Tool not found: {}", name),
                data: None,
            }),
        })
    }

    async fn handle_search_semantic(&self, req: &JsonRpcRequest, arguments: &serde_json::Value, start: Instant) -> Result<JsonRpcResponse> {
        let query = arguments.get("query").and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!("Missing 'query' argument"))?;
        let limit = arguments.get("limit").and_then(|v| v.as_u64()).unwrap_or(5);

        log::info!("🔍 Performing semantic search for: '{}'", query);
        
        // Ensure collection exists
        self.vector.ensure_collection("documentation", 1536).await?;

        let results = self.vector.search("documentation", query, limit).await?;
        
        let mut output = String::from("### Semantic Search Results\n\n");
        if results.is_empty() {
            output.push_str("No relevant documents found. Try running `index-documents` first.");
        } else {
            for (i, res) in results.iter().enumerate() {
                let score = res.get("score").and_then(|v| v.as_f64()).unwrap_or(0.0);
                let payload = res.get("payload").and_then(|v| v.as_object());
                let content = payload.and_then(|p| p.get("content")).and_then(|v| v.as_str()).unwrap_or("No content");
                let title = payload.and_then(|p| p.get("title")).and_then(|v| v.as_str()).unwrap_or("Untitled");
                
                output.push_str(&format!("{}. **{}** (Score: {:.4})\n", i + 1, title, score));
                output.push_str(&format!("   {}\n\n", content.chars().take(200).collect::<String>()));
            }
        }

        let duration_ms = start.elapsed().as_millis() as i64;
        self.record_audit_log("search-semantic", None, arguments, "success", "Semantic search completed", duration_ms).await;

        Ok(JsonRpcResponse::success(
            json!(crate::core::mcp::types::CallToolResult {
                content: vec![crate::core::mcp::types::ToolContent {
                    content_type: "text".to_string(),
                    text: Some(output),
                    image: None,
                }],
                is_error: Some(false),
            }),
            req.id.clone()
        ))
    }

    async fn handle_index_documents(&self, req: &JsonRpcRequest, arguments: &serde_json::Value, start: Instant) -> Result<JsonRpcResponse> {
        log::info!("⚙️ Starting document re-indexing into Qdrant...");
        
        // 1. Fetch all documentation from SurrealDB - select specific fields to avoid enum issues
        let mut result = self.db.query("SELECT name, title, content, sdlc_phase, string::concat(type::string(id)) AS doc_id FROM mcp_documentation").await?;
        let docs: Vec<serde_json::Value> = match result.take(0) {
            Ok(d) => d,
            Err(e) => {
                log::error!("Failed to fetch documents: {}", e);
                return Ok(JsonRpcResponse::success(
                    json!(crate::core::mcp::types::CallToolResult {
                        content: vec![crate::core::mcp::types::ToolContent {
                            content_type: "text".to_string(),
                            text: Some(format!("Error fetching documents: {}", e)),
                            image: None,
                        }],
                        is_error: Some(true),
                    }),
                    req.id.clone()
                ));
            }
        };

        // 2. Ensure collection exists (OpenAI text-embedding-3-small is 1536 dims)
        log::info!("📦 Ensuring Qdrant collection exists...");
        self.vector.ensure_collection("documentation", 1536).await?;
        log::info!("✅ Qdrant collection ready");

        let mut indexed_count = 0;
        let mut errors = Vec::new();

        log::info!("📚 Processing {} documents for indexing...", docs.len());

        for doc in docs {
            let id = doc.get("doc_id").and_then(|v| v.as_str()).unwrap_or_default().to_string();
            let name = doc.get("name").and_then(|v| v.as_str()).unwrap_or("Unnamed Document");
            let title = doc.get("title").and_then(|v| v.as_str()).unwrap_or(name);
            let content = doc.get("content").and_then(|v| v.as_str()).unwrap_or_default();
            let phase = doc.get("sdlc_phase").and_then(|v| v.as_str()).unwrap_or("unknown");
            
            if content.is_empty() { continue; }

            // Combine title and content for better embedding
            let text_to_embed = format!("Title: {}\nPhase: {}\n\n{}", title, phase, content);
            
            let metadata = json!({
                "title": title,
                "phase": phase,
                "doc_id": id
            });

            // Use doc name or part of it as id if string id is not a valid UUID
            let qdrant_id = uuid::Uuid::new_v4().to_string(); 

            log::info!("🔄 Indexing document: {}", title);
            match self.vector.upsert_document("documentation", qdrant_id, &text_to_embed, metadata).await {
                Ok(_) => indexed_count += 1,
                Err(e) => {
                    log::error!("🔥 Failed to index document {}: {}", name, e);
                    errors.push(format!("{}: {}", name, e));
                }
            }
        }

        let mut output = format!("✅ Successfully indexed {} documents into Qdrant.", indexed_count);
        if !errors.is_empty() {
            output.push_str(&format!("\n\n⚠️ Encountered {} errors:\n- {}", errors.len(), errors.join("\n- ")));
        }

        let duration_ms = start.elapsed().as_millis() as i64;
        self.record_audit_log("index-documents", None, arguments, "success", &format!("Indexed {} docs", indexed_count), duration_ms).await;

        Ok(JsonRpcResponse::success(
            json!(crate::core::mcp::types::CallToolResult {
                content: vec![crate::core::mcp::types::ToolContent {
                    content_type: "text".to_string(),
                    text: Some(output),
                    image: None,
                }],
                is_error: Some(false),
            }),
            req.id.clone()
        ))
    }
}
