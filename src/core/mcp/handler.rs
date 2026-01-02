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
        // Query resources with project names for better descriptions
        let mut result = self.db.query("
            SELECT title, project_id.name as project_name, sdlc_phase, name, mimeType 
            FROM mcp_documentation
        ").await?;
        
        let docs: Vec<serde_json::Value> = result.take(0)?;
        
        let resources: Vec<Resource> = docs.iter().map(|doc| {
            let pid = doc.get("project_name").and_then(|v| v.as_str()).unwrap_or("unknown");
            let phase = doc.get("sdlc_phase").and_then(|v| v.as_str()).unwrap_or("none");
            let name = doc.get("name").and_then(|v| v.as_str()).unwrap_or("unknown");
            let title = doc.get("title").and_then(|v| v.as_str()).unwrap_or("Untitled");
            let mime = doc.get("mimeType").and_then(|v| v.as_str()).unwrap_or("text/markdown");
            
            Resource {
                uri: format!("kyx://{}/{}/{}", pid, phase, name),
                name: title.to_string(),
                description: Some(format!("SDLC Document for {} in {} phase", pid, phase)),
                mime_type: Some(mime.to_string()),
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
        let params = req.params.as_ref().ok_or_else(|| anyhow::anyhow!("Missing params"))?;
        let uri = params.get("uri").and_then(|v| v.as_str()).ok_or_else(|| anyhow::anyhow!("Missing uri"))?;
        
        // Parse kyx://project/phase/name
        let parsed_url = Url::parse(uri)?;
        let project_name = parsed_url.host_str().ok_or_else(|| anyhow::anyhow!("Invalid project in URI"))?;
        let mut path_segments = parsed_url.path_segments().ok_or_else(|| anyhow::anyhow!("Invalid path in URI"))?;
        let sdlc_phase = path_segments.next().ok_or_else(|| anyhow::anyhow!("Missing phase in URI"))?;
        let doc_name = path_segments.next().ok_or_else(|| anyhow::anyhow!("Missing doc_name in URI"))?;

        // Query by project name and document name
        let mut result = self.db.query("
            SELECT content, mimeType FROM mcp_documentation 
            WHERE project_id.name = $project AND sdlc_phase = $phase AND name = $name
        ")
        .bind(("project", project_name.to_string()))
        .bind(("phase", sdlc_phase.to_string()))
        .bind(("name", doc_name.to_string()))
        .await?;

        let doc: Option<serde_json::Value> = result.take(0)?;

        match doc {
            Some(d) => {
                let content = d.get("content").and_then(|v| v.as_str()).unwrap_or("");
                let mime = d.get("mimeType").and_then(|v| v.as_str()).unwrap_or("text/markdown");

                // Fetch and prepend rules
                let rules = self.rules.get_combined_rules(Some(project_name)).await?;
                let final_content = if !rules.is_empty() {
                    format!("## Governance Rules\n\n{}\n\n---\n\n## Content\n\n{}", rules, content)
                } else {
                    content.to_string()
                };

                Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id: req.id.unwrap_or(json!(null)),
                    result: Some(json!({
                        "contents": [
                            ResourceContent {
                                uri: uri.to_string(),
                                mime_type: Some(mime.to_string()),
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

        let result = match name {
            "search-governance" => {
                let query = arguments.get("query").and_then(|v| v.as_str()).unwrap_or("");
                let tool = crate::core::mcp::tools::search::SearchGovernanceTool::new(self.db.clone());
                tool.execute(query).await?
            },
            "list-projects" => {
                let tool = crate::core::mcp::tools::list::ListProjectsTool::new(self.db.clone());
                tool.execute().await?
            },
            "list-documents" => {
                let project_filter = arguments.get("project").and_then(|v| v.as_str());
                let tool = crate::core::mcp::tools::list::ListDocumentsTool::new(self.db.clone());
                tool.execute(project_filter).await?
            },
            "list-tech-stack" => {
                let tool = crate::core::mcp::tools::list::ListTechStackTool::new(self.db.clone());
                tool.execute().await?
            },
            _ => {
                // Try to find a dynamic tool in the database
                let mut tool_query = self.db.query("SELECT * FROM mcp_tool WHERE name = $name AND enabled = true")
                    .bind(("name", name.to_string()))
                    .await?;
                
                let tool_opt: Option<Tool> = tool_query.take(0)?;

                if let Some(tool) = tool_opt {
                    if let Some(exec_type) = &tool.execution_type {
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
                                                    // Workaround: Unwrap strings to avoid 'invalid type: enum' serialization issues with Value
                                                    if let Some(s) = val.as_str() {
                                                        query = query.bind((sql_var_str.to_string(), s.to_string()));
                                                    } else {
                                                        query = query.bind((sql_var_str.to_string(), val.clone()));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                let mut result = query.await?;
                                let output: Vec<serde_json::Value> = result.take(0)?;
                                let json_output = serde_json::to_string_pretty(&output)?;

                                // Wrap result in JsonRpcResponse
                                return Ok(JsonRpcResponse {
                                    jsonrpc: "2.0".to_string(),
                                    id: req.id.unwrap_or(json!(null)),
                                    result: Some(json!(crate::core::mcp::types::CallToolResult {
                                        content: vec![crate::core::mcp::types::ToolContent {
                                            content_type: "text".to_string(),
                                            text: Some(format!("Dynamic Tool Result:\n```json\n{}\n```", json_output)),
                                            image: None,
                                        }],
                                        is_error: Some(false),
                                    })),
                                    error: None,
                                });
                            }
                        }
                    }
                }

                // If no dynamic tool found either
                return Ok(JsonRpcResponse {
                    jsonrpc: "2.0".to_string(),
                    id: req.id.unwrap_or(json!(null)),
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32601,
                        message: format!("Tool not found: {}", name),
                        data: None,
                    }),
                });
            }
        };

        Ok(JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: req.id.unwrap_or(json!(null)),
            result: Some(json!(result)),
            error: None,
        })
    }
}
