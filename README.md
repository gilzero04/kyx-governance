# Kyx MCP Server

The **Kyx Model Context Protocol (MCP) Server** is the central governance and intelligence engine for the Kyx ecosystem. It provides AI agents with tools to access governance rules, manage projects, and report incidents.

## Features

- **Governance Checks**: `search-governance`, `list-documents`
- **Project Index**: `list-projects`, `list-tech-stack`
- **Incident Management**: `count-incidents`, `report-incident` (Dynamic Tool)
- **Database-Driven Logic**: Architecture stores rules and tools in SurrealDB for dynamic updates.

## Getting Started

### Configuration (Claude Desktop)

Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "kyx-governance": {
      "command": "/absolute/path/to/kyx-governance/run-mcp.sh",
      "args": []
    }
  }
}
```

Ensure `run-mcp.sh` is executable (`chmod +x run-mcp.sh`) and has the correct path.

## Available Tools

### `report-incident` (New!)

Records a new incident directly into the governance database.

- **Parameters**:
  - `title`: Short description of the issue.
  - `symptom`: Observable behavior.
  - `status`: Incident status (`identified`, `investigating`, `solved`).
  - `project`: Project name (e.g., `kyx-governance`).
  - `language`: Primary programming language involved.
- **Usage**:
  ```
  call report-incident(title="Memory Leak", symptom="OOM Crash", status="identified", project="kyx-governance", language="Rust")
  ```

### `search-governance`

Search for rules, standards, and past incidents.

- **Usage**:
  ```
  call search-governance(query="naming convention")
  ```

## Governance Rules

_Auto-generated from Database_

1. **Documentation Autonomy**: AI is authorized to update documentation immediately.
2. **Quality Assurance**: Verify before finishing.
3. **Incident Reporting**: Record incidents if not found in search.

---

_Maintained by Kyx Governance Engine_
