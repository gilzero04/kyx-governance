USE NS kyx;
USE DB governance;

BEGIN TRANSACTION;

-- Wipe existing data for clean seed
DELETE ai_rules;
DELETE mcp_documentation;
DELETE mcp_tools;
DELETE mcp_incident;
DELETE mcp_projects;

-- ==========================================
-- 1. PROJECTS (Fixed IDs for strict separation)
-- ==========================================

-- Global
CREATE mcp_projects:global CONTENT { 
    name: "kyx-global", 
    description: "Organization-wide Governance Standards", 
    active: true 
};

-- Kernel
CREATE mcp_projects:kernel CONTENT { 
    name: "kyx-kernel", 
    description: "Core Engine and Logic Layer", 
    active: true 
};

-- Signal
CREATE mcp_projects:signal CONTENT { 
    name: "kyx-signal", 
    description: "Real-time Communication and Event Hub", 
    active: true 
};

-- Infra
CREATE mcp_projects:infra CONTENT { 
    name: "kyx-infra", 
    description: "Infrastructure Automation and Managed Services", 
    active: true 
};

-- Governance (Hub & Remote)
CREATE mcp_projects:governance CONTENT { 
    name: "kyx-governance", 
    description: "Governance Hub, Metadata Repository, and Remote Proxy", 
    active: true 
};

COMMIT TRANSACTION;
