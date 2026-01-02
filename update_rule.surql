USE NS kyx;
USE DB governance;
UPDATE ai_rules 
SET content = 'Security Rule: Generated passwords and secrets MUST be at least 32 bytes long and use high entropy characters. IMPORTANT: To prevent connection string parsing errors, generated passwords MUST NOT contain the following characters: "@" (at), ":" (colon), "/" (slash), "?" (question), "#" (hash), "[" (left bracket), "]" (right bracket), "\\" (backslash), "\'" (single quote), """ (double quote), "$" (dollar), or whitespace.' 
WHERE priority = 90;
