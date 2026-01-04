# Project Documentation

Welcome to the Kyx Governance documentation. This directory contains technical guides, walkthroughs, and design documents.

## Walkthroughs

Detailed guides on major feature implementations:

- [Phase 2: Audit Logging (02-audit-logging.md)](./walkthroughs/02-audit-logging.md) - Implementation of the audit trail system and SurrealDB 2.x serialization solutions.

## Architecture

- [Database Schema](../migrations/01_schema.surql) - Table definitions and relationships.
- [McpHandler](../src/core/mcp/handler.rs) - Core logic for tool execution and auditing.
