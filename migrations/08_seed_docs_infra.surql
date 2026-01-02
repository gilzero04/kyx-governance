USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- PRD
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:infra,
    sdlc_phase: "planning",
    name: "prd",
    title: "Infrastructure PRD",
    content: "# Kyx Infra PRD\n\n## Objective\nTo automate the deployment, monitoring, and scaling of the Kyx ecosystem using modern DevOps practices.\n\n## Core Features\n1. **Auto-Provisioning**: Automated setup of PostgreSQL, Redis, and Qdrant.\n2. **Monitoring**: Centralized logging and metrics with Prometheus/Grafana.\n3. **Security**: Hardened container images and network policies.",
    mimeType: "text/markdown"
};

-- Architecture (Infra)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:infra,
    sdlc_phase: "design",
    name: "architecture",
    title: "Infrastructure Architecture",
    content: "# Kyx Infrastructure Architecture\n\n## Tech Stack\n- **Orchestration**: Docker Compose (Dev) / Kubernetes (Prod)\n- **Monitoring**: Prometheus & Grafana\n- **Logging**: Fluentd + Elasticsearch (EFK Stack)\n\n## Components\n1. **Service Mesh**: Handles internal service communication.\n2. **Monitoring Gateway**: Centralized dashboard for system health.\n3. **CI/CD Pipeline**: GitHub Actions for automated deployment.",
    mimeType: "text/markdown"
};

-- Test Plan (Infra)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:infra,
    sdlc_phase: "verification",
    name: "test-plan",
    title: "Infrastructure Test Plan",
    content: "# Infrastructure Verification\n\n## Security Audit\n- Automated vulnerability scanning for Docker images.\n- Network policy isolation tests.\n\n## Recovery\n- Disaster recovery drills (Database backup/restore verification).",
    mimeType: "text/markdown"
};

-- Master Workflow (Infra)
CREATE mcp_documentation CONTENT {
    project_id: mcp_projects:infra,
    sdlc_phase: "maintenance",
    name: "project-workflow-status",
    title: "Master Workflow: Kyx Infra",
    content: "# Master Workflow: Kyx Infra\n\n## Status: Operational\n\n- [x] PLAN: PRD (Complete)\n- [x] DESIGN: Architecture (Complete)\n- [x] IMPLEMENTATION: CI/CD Pipelines (Complete)\n- [x] VERIFICATION: Test Plan & Security Audits (Complete)",
    mimeType: "text/markdown"
};

COMMIT TRANSACTION;
