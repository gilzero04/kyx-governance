use crate::core::database::Database;
use crate::core::mcp::{JsonRpcRequest, JsonRpcResponse, McpInitializeResult, ServerInfo, JsonRpcError};
use crate::core::mcp::types::{Resource, ResourceContent, Tool};
use crate::core::mcp::rules::RuleManager;
use serde_json::json;
use anyhow::Result;
use url::Url;

pub struct McpHandler {
    db: Database,
    rules: RuleManager,
}

impl McpHandler {
    pub fn new(db: Database) -> Self {
        Self { 
            db: db.clone(), 
            rules: RuleManager::new(db) 
        }
    }

    pub async fn handle_request(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
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
                // Return empty success - notifications don't require response but we send one anyway
                return Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id,
                    result: Some(json!({})),
                    error: None,
                });
            },
            _ => {
                return Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id,
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32601,
                        message: format!("Method not found: {}", req.method),
                        data: None,
                    }),
                });
            }
        };

        match result {
            Ok(resp) => Ok(resp),
            Err(e) => {
                log::error!("🔥 Error handling MCP request: {}", e);
                Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id,
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32000,
                        message: e.to_string(),
                        data: None,
                    }),
                })
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
        let mut result = self.db.query("SELECT * FROM mcp_tool WHERE enabled = true").await?;

        let mut tools: Vec<Tool> = result.take(0).unwrap_or_default();

        // 🛠️ Dynamic Fix: Parse JSON strings if parameters/schema are stored as strings in DB
        for tool in &mut tools {
            if let serde_json::Value::String(s) = &tool.input_schema {
                if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(s) {
                    tool.input_schema = parsed;
                }
            }
        }

        // If no tools in database, provide a default hardcoded tool
        if tools.is_empty() {
             tools.push(Tool {
                name: "search-governance".to_string(),
                title: Some("Search Governance Documents".to_string()),
                description: Some("Search through governance standards and SDLC documentation".to_string()),
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

    async fn handle_tools_call(&self, req: JsonRpcRequest) -> Result<JsonRpcResponse> {
        let params = req.params.as_ref().ok_or_else(|| anyhow::anyhow!("Missing params"))?;
        let name = params.get("name").and_then(|v| v.as_str()).ok_or_else(|| anyhow::anyhow!("Missing name"))?;
        let arguments = params.get("arguments").ok_or_else(|| anyhow::anyhow!("Missing arguments"))?;

        log::info!("🛠️ Dispatching tool call: {}", name);

        // Try to find a dynamic tool in the database
        let mut tool_query = self.db.query("SELECT * FROM mcp_tool WHERE name = $name AND enabled = true")
            .bind(("name", name.to_string()))
            .await?;
        
        let tool_opt: Option<Tool> = tool_query.take(0)?;

        if let Some(tool) = tool_opt {
            if let Some(exec_type) = &tool.execution_type {
            if exec_type == "raw_sql" {
                // Execute arbitrary SQL from arguments
                let sql = arguments.get("sql_commands")
                    .and_then(|v| v.as_str())
                    .or_else(|| arguments.get("sql").and_then(|v| v.as_str()))
                    .ok_or_else(|| anyhow::anyhow!("Missing 'sql_commands' or 'sql' argument for raw_sql execution"))?;

                log::info!("🚀 Executing Raw SQL Tool: {}", name);
                let mut result = self.db.query(sql).await?;
                
                let mut all_results = Vec::new();
                let mut i: usize = 0;
                while let Ok(val) = result.take::<Vec<serde_json::Value>>(i) {
                    for v in val {
                        if !v.is_null() {
                            all_results.push(v);
                        }
                    }
                    i += 1;
                    if i > 50 { break; } 
                }
                
                let text_output = if all_results.len() == 1 && all_results[0].is_string() {
                    all_results[0].as_str().unwrap_or("").to_string()
                } else {
                    let json_output = serde_json::to_string_pretty(&all_results)?;
                    format!("Raw SQL Result:\n```json\n{}\n```", json_output)
                };

                return Ok(JsonRpcResponse::success(
                    json!(crate::core::mcp::types::CallToolResult {
                        content: vec![crate::core::mcp::types::ToolContent {
                            content_type: "text".to_string(),
                            text: Some(text_output),
                            image: None,
                        }],
                        is_error: Some(false),
                    }),
                    req.id
                ));
            }

            if exec_type == "dynamic_sql" {
                    if let Some(sql) = &tool.sql_template {
                        // Dynamic execution
                        log::info!("🚀 Executing Dynamic Tool: {}", name);
                        
                        let mut query = self.db.query(sql);

                        // Map parameters
                        if let Some(param_map_val) = &tool.parameter_map {
                            // Handle both Object (standard) and String (workaround)
                            let param_map_obj = if let Some(obj) = param_map_val.as_object() {
                                Some(obj.clone())
                            } else if let Some(s) = param_map_val.as_str() {
                                serde_json::from_str::<serde_json::Map<String, serde_json::Value>>(s).ok()
                            } else {
                                None
                            };

                            if let Some(param_map) = param_map_obj {
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
                        
                        let mut result = query.await?;
                    
                    let mut all_results = Vec::new();
                    let mut i: usize = 0;
                    while let Ok(val) = result.take::<Vec<serde_json::Value>>(i) {
                        for v in val {
                            if !v.is_null() {
                                all_results.push(v);
                            }
                        }
                        i += 1;
                        if i > 50 { break; } 
                    }

                    let text_output = if all_results.len() == 1 && all_results[0].is_string() {
                        all_results[0].as_str().unwrap_or("").to_string()
                    } else {
                        let json_output = serde_json::to_string_pretty(&all_results)?;
                        format!("Dynamic Tool Result:\n```json\n{}\n```", json_output)
                    };

                    return Ok(JsonRpcResponse::success(
                        json!(crate::core::mcp::types::CallToolResult {
                            content: vec![crate::core::mcp::types::ToolContent {
                                content_type: "text".to_string(),
                                text: Some(text_output),
                                image: None,
                            }],
                            is_error: Some(false),
                        }),
                        req.id
                    ));
                    }
                }
            }
        }

        // If no tool found
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
}
